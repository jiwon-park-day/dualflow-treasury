defmodule DualflowTreasury.Billing do
  @moduledoc """
  Context for recurring bill management and predictions.

  Handles:
  - Recurring bill processing and tracking
  - Bill prediction algorithm
  - Bill history records
  - Daily bill amount calculations
  - Credit card payment integration
  """

  import Ecto.Query, warn: false
  alias DualflowTreasury.Repo
  alias DualflowTreasury.Billing.{RecurringBill, RecurringBillHistory}

  @buffer_percentage Decimal.new("0.10")

  # Recurring bills

  # Creates a recurring bill record in the database.
  defp create_recurring_bill(attrs) do
    %RecurringBill{}
    |> RecurringBill.changeset(attrs)
    |> Repo.insert()
  end

  # Creates a new recurring bill from a transaction.
  defp create_recurring_bill_from_transaction(transaction) do
    attrs = %{
      account_id: transaction.account_id,
      merchant_id: transaction.merchant_id,
      description: transaction.description,
      predicted_amount: Decimal.abs(transaction.amount),
      monthly_due_day: transaction.date.day,
      is_active: true
    }

    create_recurring_bill(attrs)
  end

  # Updates a recurring bill's attributes.
  defp update_recurring_bill(bill_id, attrs) do
    with {:ok, bill} <- get_recurring_bill(bill_id) do
      bill
      |> RecurringBill.changeset(attrs)
      |> Repo.update()
    end
  end

  @doc """
  Activates a recurring bill.

  Sets is_active to true, enabling the bill to be included in daily calculations.
  """
  def activate_recurring_bill(bill_id) do
    update_recurring_bill(bill_id, %{is_active: true})
  end

  @doc """
  Deactivates a recurring bill.

  Sets is_active to false without deleting the record.
  Preserves bill history while excluding the bill from future calculations.
  """
  def deactivate_recurring_bill(bill_id) do
    update_recurring_bill(bill_id, %{is_active: false})
  end

  # Activates a bill only if currently inactive.
  defp maybe_activate_bill(bill) do
    if bill.is_active do
      {:ok, bill}
    else
      activate_recurring_bill(bill.id)
    end
  end

  # Gets a recurring bill by ID.
  defp get_recurring_bill(bill_id) do
    case Repo.get(RecurringBill, bill_id) do
      nil -> {:error, :bill_not_found}
      bill -> {:ok, bill}
    end
  end

  @doc """
  Gets all recurring bills for an account.

  Returns both active and inactive bills.
  """
  def get_account_recurring_bills(account_id) do
    bills =
      RecurringBill
      |> where(account_id: ^account_id)
      |> Repo.all()

    {:ok, bills}
  end

  @doc """
  Gets all recurring bills for an account on a specific due day.

  Returns both active and inactive bills.
  """
  def get_account_recurring_bills(account_id, due_day) do
    bills =
      RecurringBill
      |> where(account_id: ^account_id)
      |> where(monthly_due_day: ^due_day)
      |> Repo.all()

    {:ok, bills}
  end

  @doc """
  Gets all active recurring bills for an account.

  Filters to only bills where is_active = true.
  """
  def get_account_active_recurring_bills(account_id) do
    bills =
      RecurringBill
      |> where(account_id: ^account_id, is_active: true)
      |> Repo.all()

    {:ok, bills}
  end

  @doc """
  Gets active recurring bills for an account on a specific due day.

  Used by calculate_total_bill_amount to sum bills due on a given date.
  """
  def get_account_active_recurring_bills(account_id, due_day) do
    bills =
      RecurringBill
      |> where(account_id: ^account_id)
      |> where(monthly_due_day: ^due_day)
      |> where(is_active: true)
      |> Repo.all()

    {:ok, bills}
  end

  @doc """
  Gets a specific recurring bill by account, merchant, and due day.

  Used to identify bills uniquely, as the same merchant may have
  multiple bills with different due dates.
  """
  def get_account_recurring_bill(account_id, merchant_id, due_day) do
    case Repo.get_by(RecurringBill,
           account_id: account_id,
           merchant_id: merchant_id,
           monthly_due_day: due_day
         ) do
      nil -> {:error, :bill_not_found}
      bill -> {:ok, bill}
    end
  end

  # Recurring bill processing

  @doc """
  Processes a recurring transaction by:
  1. Finding or creating a recurring bill record
  2. Activating the bill if inactive
  3. Creating bill history entry
  4. Updating bill predictions based on history

  Called by Treasury.process_transaction when is_recurring = true.
  All operations are wrapped in a database transaction for atomicity.
  """
  def process_recurring_bill(transaction) do
    Repo.transaction(fn ->
      case get_account_recurring_bill(
             transaction.account_id,
             transaction.merchant_id,
             transaction.date.day
           ) do
        # Existing bill
        {:ok, bill} ->
          with {:ok, bill} <- maybe_activate_bill(bill),
               {:ok, _history} <-
                 create_recurring_bill_history(%{
                   bill_id: bill.id,
                   actual_amount: Decimal.abs(transaction.amount),
                   predicted_amount: bill.predicted_amount,
                   transaction_id: transaction.id
                 }),
               {:ok, new_pred} <- predict_bill_amount(bill.id),
               {:ok, updated_bill} <-
                 update_recurring_bill(bill.id, %{predicted_amount: new_pred}) do
            updated_bill
          else
            {:error, reason} -> Repo.rollback(reason)
          end

        # New bill
        {:error, :bill_not_found} ->
          with {:ok, new_bill} <- create_recurring_bill_from_transaction(transaction),
               {:ok, _history} <-
                 create_recurring_bill_history(%{
                   bill_id: new_bill.id,
                   actual_amount: Decimal.abs(transaction.amount),
                   transaction_id: transaction.id
                 }) do
            new_bill
          else
            {:error, reason} -> Repo.rollback(reason)
          end
      end
    end)
  end

  # Bill history

  # Creates a recurring bill history entry.
  # Prediction error is calculated automatically in the schema changeset.
  defp create_recurring_bill_history(attrs) do
    %RecurringBillHistory{}
    |> RecurringBillHistory.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets bill history for a specific recurring bill.

  Returns all history entries ordered by insertion date.
  History includes actual amounts, predictions, and prediction errors.
  """
  def get_recurring_bill_history(bill_id) do
    history =
      RecurringBillHistory
      |> where(bill_id: ^bill_id)
      |> Repo.all()

    {:ok, history}
  end

  # Bill prediction

  # Predicts the next bill amount based on historical data.
  # Uses weighted average with recent emphasis (50/30/20) and error adjustment.
  # Requires at least 2 history entries to make a prediction.
  defp predict_bill_amount(bill_id) do
    {:ok, history} = get_recurring_bill_history(bill_id)

    if length(history) < 2 do
      {:error, :insufficient_history}
    else
      sorted_history = Enum.sort_by(history, & &1.inserted_at, :desc)

      case sorted_history do
        [latest | rest] when length(rest) >= 1 ->
          [second | older] = rest

          # 50% most recent, 30% second most recent
          weighted_prediction =
            latest.actual_amount
            |> Decimal.mult(Decimal.new("0.5"))
            |> Decimal.add(Decimal.mult(second.actual_amount, Decimal.new("0.3")))

          # 20% weight to average of older payments
          older_contribution =
            if length(older) > 0 do
              older_avg =
                older
                |> Enum.map(& &1.actual_amount)
                |> Enum.reduce(&Decimal.add/2)
                |> Decimal.div(length(older))

              Decimal.mult(older_avg, Decimal.new("0.2"))
            else
              Decimal.new("0.00")
            end

          base_prediction = Decimal.add(weighted_prediction, older_contribution)

          # Add recent under-prediction errors
          recent_error_adjustment = calculate_recent_error_adjustment(sorted_history)
          prediction = Decimal.add(base_prediction, recent_error_adjustment)
          {:ok, prediction}
      end
    end
  end

  # Calculates adjustment based on recent prediction errors.
  # Only considers positive errors (under-predictions) to remain conservative.
  # Returns 40% of the average recent under-prediction.
  defp calculate_recent_error_adjustment(history) do
    # Look at last 3 prediction errors, average positive ones only
    recent_positive_errors =
      history
      |> Enum.take(3)
      |> Enum.map(&(&1.prediction_error || Decimal.new("0.00")))
      |> Enum.filter(&(Decimal.compare(&1, Decimal.new("0.00")) == :gt))

    case recent_positive_errors do
      [] ->
        Decimal.new("0.00")

      errors ->
        errors
        |> Enum.reduce(&Decimal.add/2)
        |> Decimal.div(length(errors))
        # 40% of recent avg under-prediction
        |> Decimal.mult(Decimal.new("0.4"))
    end
  end

  # Daily bill amount

  @doc """
  Calculates total predicted bill amount for a specific date.

  Includes:
  - Sum of all active bills due on the given date
  - 10% safety buffer applied to the total

  Returns total amount needed for bills on the specified date.
  Called by Treasury.make_daily_transfer_decision.
  """
  def calculate_total_bill_amount(account_id, date) do
    with {:ok, bills} <- get_account_active_recurring_bills(account_id, date.day) do
      base_total =
        bills
        |> Enum.map(& &1.predicted_amount)
        |> Enum.reduce(Decimal.new("0.00"), &Decimal.add/2)

      safety_buffer = Decimal.mult(@buffer_percentage, base_total)
      total_with_buffer = Decimal.add(base_total, safety_buffer)

      {:ok, total_with_buffer}
    end
  end

  # Credit card bill

  @doc """
  Creates a credit card payment as a recurring bill.

  Called by CreditCards context when a statement closes.
  The merchant_id should be the credit card identifier.
  """
  def create_credit_card_bill(account_id, merchant_id, statement_balance, payment_due_day) do
    attrs = %{
      account_id: account_id,
      merchant_id: merchant_id,
      description: "Credit Card Payment",
      predicted_amount: statement_balance,
      monthly_due_day: payment_due_day,
      is_active: true
    }

    create_recurring_bill(attrs)
  end

  @doc """
  Updates or creates a credit card payment recurring bill.

  Called monthly when credit card statements close.
  Updates the predicted amount to match the new statement balance.
  """
  def update_credit_card_bill(account_id, merchant_id, statement_balance, payment_due_day) do
    case get_account_recurring_bill(account_id, merchant_id, payment_due_day) do
      {:error, :bill_not_found} ->
        create_credit_card_bill(account_id, merchant_id, statement_balance, payment_due_day)

      {:ok, bill} ->
        update_recurring_bill(bill.id, %{predicted_amount: statement_balance})
    end
  end
end
