defmodule DualflowTreasury.Billing do
  @moduledoc """
  Context for recurring bill management and predictions

  Handles:
  - Recurring bill processing & tracking
  - Bill prediction algorithm
  - Bill history records
  - Daily bill amount calculations




  """

  import Ecto.Query, warn: false
  alias DualflowTreasury.Repo
  alias DualflowTreasury.Billing.{RecurringBill, RecurringBillHistory}

  @buffer_percentage Decimal.new("0.10")

  # Recurring bill processing

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

  # Recurring bills

  defp create_recurring_bill(attrs) do
    %RecurringBill{}
    |> RecurringBill.changeset(attrs)
    |> Repo.insert()
  end

  def create_recurring_bill_from_transaction(transaction) do
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

  defp update_recurring_bill(bill_id, attrs) do
    with {:ok, bill} <- get_recurring_bill(bill_id) do
      bill
      |> RecurringBill.changeset(attrs)
      |> Repo.update()
    end
  end

  def activate_recurring_bill(bill_id) do
    update_recurring_bill(bill_id, %{is_active: true})
  end

  def deactivate_recurring_bill(bill_id) do
    update_recurring_bill(bill_id, %{is_active: false})
  end

  defp maybe_activate_bill(bill) do
    if bill.is_active do
      {:ok, bill}
    else
      activate_recurring_bill(bill.id)
    end
  end

  defp get_recurring_bill(bill_id) do
    case Repo.get(RecurringBill, bill_id) do
      nil -> {:error, :bill_not_found}
      bill -> {:ok, bill}
    end
  end

  def get_account_recurring_bills(account_id) do
    bills =
      RecurringBill
      |> where(account_id: ^account_id)
      |> Repo.all()

    {:ok, bills}
  end

  def get_account_recurring_bills(account_id, due_day) do
    bills =
      RecurringBill
      |> where(account_id: ^account_id)
      |> where(monthly_due_day: ^due_day)
      |> Repo.all()

    {:ok, bills}
  end

  def get_account_active_recurring_bills(account_id) do
    bills =
      RecurringBill
      |> where(account_id: ^account_id, is_active: true)
      |> Repo.all()

    {:ok, bills}
  end

  def get_account_active_recurring_bills(account_id, due_day) do
    bills =
      RecurringBill
      |> where(account_id: ^account_id)
      |> where(monthly_due_day: ^due_day)
      |> where(is_active: true)
      |> Repo.all()

    {:ok, bills}
  end


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

  # Bill history

  defp create_recurring_bill_history(attrs) do
    %RecurringBillHistory{}
    |> RecurringBillHistory.changeset(attrs)
    |> Repo.insert()
  end

  def get_recurring_bill_history(bill_id) do
    history =
      RecurringBillHistory
      |> where(bill_id: ^bill_id)
      |> Repo.all()

    {:ok, history}
  end

  # Bill prediction

  defp predict_bill_amount(bill_id) do
    # Bill history
    history = get_recurring_bill_history(bill_id)

    # Calculate

  end

  # Daily bill amount

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
end
