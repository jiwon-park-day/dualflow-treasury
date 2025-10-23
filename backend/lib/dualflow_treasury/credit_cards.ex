defmodule DualflowTreasury.CreditCards do
  @moduledoc """
  Context for credit card operations.

  Handles:
  - Credit card management
  - Credit card transactions
  - Statement closing process
  - Payment processing

  Note: Credit cards in this system operate as charge cards.
  - Full statement balance must be paid by the payment due date
  - No minimum payments or interest charges apply.
  """

  import Ecto.Query, warn: false
  alias DualflowTreasury.Repo
  alias DualflowTreasury.CreditCards.{CreditCard, CreditCardTransaction}
  alias DualflowTreasury.{Accounts, Treasury, Billing}

  @default_statement_closing_day 15
  @default_payment_due_day 10
  @default_merchant_id "DUALFLOW_BUSINESS_CC"

  # Credit card operations

  # Creates a credit card record in the database.
  defp create_credit_card(attrs) do
    %CreditCard{}
    |> CreditCard.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a credit card for a customer.

  Creates both the credit card and an initial recurring bill entry in the Billing context with predicted_amount = 0.
  Uses default statement closing day (15th) and payment due day (10th).
  All operations wrapped in a database transaction for atomicity.
  """
  def create_customer_credit_card(customer_id, credit_limit) do
    Repo.transaction(fn ->
      attrs = %{
        customer_id: customer_id,
        credit_limit: credit_limit,
        statement_closing_day: @default_statement_closing_day,
        payment_due_day: @default_payment_due_day
      }

      with {:ok, card} <- create_credit_card(attrs),
           {:ok, checking} <- Accounts.get_customer_checking_account(customer_id),
           {:ok, _bill} <-
             Billing.create_credit_card_bill(
               checking.id,
               @default_merchant_id,
               Decimal.new("0.00"),
               card.payment_due_day
             ) do
        card
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Updates a credit card's attributes.
  """
  def update_credit_card(card_id, attrs) do
    with {:ok, card} <- get_credit_card(card_id) do
      card
      |> CreditCard.changeset(attrs)
      |> Repo.update()
    end
  end

  # Updates a credit card's current balance to a new value.
  defp update_credit_card_current_balance(card_id, new_balance) do
    update_credit_card(card_id, %{current_balance: new_balance})
  end

  # Adjusts a credit card's current balance by the given amount.
  defp adjust_credit_card_current_balance(card_id, amount) do
    with {:ok, card} <- get_credit_card(card_id) do
      new_balance = Decimal.add(card.current_balance, amount)
      update_credit_card(card_id, %{current_balance: new_balance})
    end
  end

  # Updates a credit card's statement balance to a new value.
  defp update_credit_card_statement_balance(card_id, new_balance) do
    update_credit_card(card_id, %{statement_balance: new_balance})
  end

  @doc """
  Gets a credit card by ID.
  """
  def get_credit_card(card_id) do
    case Repo.get(CreditCard, card_id) do
      nil -> {:error, :card_not_found}
      card -> {:ok, card}
    end
  end

  @doc """
  Gets all credit cards in the system.
  """
  def get_all_credit_cards() do
    credit_cards = Repo.all(CreditCard)
    {:ok, credit_cards}
  end

  @doc """
  Gets the credit card for a customer.

  Currently supports one card per customer.
  """
  def get_customer_credit_card(customer_id) do
    case Repo.get_by(CreditCard, customer_id: customer_id) do
      nil -> {:error, :card_not_found}
      card -> {:ok, card}
    end
  end

  # Credit card transactions

  # Creates a credit card transaction record in the database.
  defp create_credit_card_transaction(attrs) do
    %CreditCardTransaction{}
    |> CreditCardTransaction.changeset(attrs)
    |> Repo.insert()
  end

  # Gets a credit card transaction by ID.
  defp get_credit_card_transaction(transaction_id) do
    case Repo.get(CreditCardTransaction, transaction_id) do
      nil -> {:error, :transaction_not_found}
      transaction -> {:ok, transaction}
    end
  end

  @doc """
  Gets all transactions for a credit card, ordered by date (newest first).
  """
  def get_credit_card_transactions(card_id) do
    transactions =
      CreditCardTransaction
      |> where(credit_card_id: ^card_id)
      |> order_by([t], desc: t.transaction_date, desc: t.id)
      |> Repo.all()

    {:ok, transactions}
  end

  @doc """
  Gets credit card transactions within a date range, ordered by date (newest first).
  """
  def get_credit_card_transactions(card_id, start_date, end_date) do
    transactions =
      CreditCardTransaction
      |> where(credit_card_id: ^card_id)
      |> where([t], t.transaction_date >= ^start_date and t.transaction_date <= ^end_date)
      |> order_by([t], desc: t.transaction_date, desc: t.id)
      |> Repo.all()

    {:ok, transactions}
  end

  @doc """
  Gets credit card transactions by category, ordered by date (newest first)
  """
  def get_credit_card_transactions_by_category(card_id, category) do
    transactions =
      CreditCardTransaction
      |> where(credit_card_id: ^card_id)
      |> where([t], t.category == ^category)
      |> order_by([t], desc: t.transaction_date, desc: t.id)
      |> Repo.all()

    {:ok, transactions}
  end

  @doc """
  Processes a credit card transaction by:
  1. Creating the credit card transaction record
  2. Updating the card's current balance

  Amount should be positive for charges, negative for refunds/credits.
  All operations wrapped in a database transaction for atomicity.

  ## Parameters
  - transaction_data: Map with fields (credit_card_id, amount, description*, transaction_date, category*) *optional
  """
  def process_credit_card_transaction(transaction_data) do
    Repo.transaction(fn ->
      with {:ok, cc_transaction} <- create_credit_card_transaction(transaction_data),
           {:ok, _card} <-
             adjust_credit_card_current_balance(
               cc_transaction.credit_card_id,
               cc_transaction.amount
             ) do
        cc_transaction
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  # Statement closing & payment

  @doc """
  Processes monthly statement closing for a credit card.

  Called on the statement closing day (15th of month):
  1. Sets statement_balance to current_balance
  2. Resets current_balance to zero
  3. Updates recurring bill in Billing context with new statement balance

  All operations wrapped in a database transaction for atomicity.
  """
  def process_statement_closing(card_id) do
    Repo.transaction(fn ->
      with {:ok, card} <- get_credit_card(card_id),
           {:ok, checking} <- Accounts.get_customer_checking_account(card.customer_id),

           # Update statement balance
           {:ok, _card} <- update_credit_card_statement_balance(card_id, card.current_balance),

           # Reset current balance
           {:ok, updated_card} <-
             update_credit_card_current_balance(card_id, Decimal.new("0.00")),

           # Update credit card bill
           {:ok, _bill} <-
             Billing.update_credit_card_bill(
               checking.id,
               @default_merchant_id,
               updated_card.statement_balance,
               updated_card.payment_due_day
             ) do
        updated_card
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Processes automatic credit card payment from checking account.
  Pays full statement balance automatically.

  Called on payment due day (10th of month):
  1. Debits checking account for statement balance amount
  2. Credits credit card (creates negative transaction)
  3. Resets statement_balance to zero

  All operations wrapped in a database transaction for atomicity.
  """
  def process_automatic_credit_card_payment(card_id, payment_date) do
    Repo.transaction(fn ->
      with {:ok, card} <- get_credit_card(card_id),
           {:ok, account} <- Accounts.get_customer_checking_account(card.customer_id),

           # Create checking transaction (debit)
           {:ok, _transaction} <-
             Treasury.process_transaction(%{
               account_id: account.id,
               date: payment_date,
               amount: Decimal.negate(card.statement_balance),
               merchant_id: @default_merchant_id,
               description: "Credit Card Payment - Auto",
               category: "credit_card_payment",
               is_recurring: false
             }),

           # Create credit card transaction
           {:ok, cc_transaction} <-
             create_credit_card_transaction(%{
               credit_card_id: card_id,
               amount: Decimal.negate(card.statement_balance),
               description: "Payment - Auto",
               transaction_date: payment_date,
               category: "payment"
             }),

           # Reset statement balance
           {:ok, _card} <- update_credit_card_statement_balance(card_id, Decimal.new("0.00")) do
        cc_transaction
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Processes manual credit card payment from checking account.

  Allows businesses to make off-cycle payments to reduce balance and free up credit before the next statement closes.
  Payments are applied to the oldest obligation first (statement balance -> current_balance).
  Overpayments are allowed and will create a credit balance on the card.

  Returns detailed allocation information showing how the payment was distributed.
  """
  def process_manual_credit_card_payment(card_id, payment_amount, payment_date) do
    with {:ok, _amount} <- validate_payment_amount(payment_amount) do
      Repo.transaction(fn ->
        with {:ok, card} <- get_credit_card(card_id),
             {:ok, account} <- Accounts.get_customer_checking_account(card.customer_id),

             # Create checking transaction (debit)
             {:ok, _transaction} <-
               Treasury.process_transaction(%{
                 account_id: account.id,
                 date: payment_date,
                 amount: Decimal.negate(payment_amount),
                 merchant_id: @default_merchant_id,
                 description: "Credit Card Payment - Manual",
                 category: "credit_card_payment",
                 is_recurring: false
               }),

             # Create credit card transaction
             {:ok, cc_transaction} <-
               create_credit_card_transaction(%{
                 credit_card_id: card_id,
                 amount: Decimal.negate(payment_amount),
                 description: "Payment - Manual",
                 transaction_date: payment_date,
                 category: "payment"
               }),

             # Update balances
             {:ok, new_balances} <-
               calculate_payment_allocation(
                 payment_amount,
                 card.statement_balance,
                 card.current_balance
               ),
             {:ok, _card} <-
               update_credit_card_statement_balance(card_id, new_balances.statement_balance),
             {:ok, _card} <-
               update_credit_card_current_balance(card_id, new_balances.current_balance) do
          %{
            transaction: cc_transaction,
            applied_to_statement: new_balances.applied_to_statement,
            applied_to_current: new_balances.applied_to_current
          }
        else
          {:error, reason} -> Repo.rollback(reason)
        end
      end)
    end
  end

  # Validates that payment amount is positive.
  defp validate_payment_amount(amount) do
    if Decimal.compare(amount, Decimal.new("0")) == :gt do
      {:ok, amount}
    else
      {:error, :invalid_payment_amount}
    end
  end

  # Calculates how a payment amount should be allocated between statement and current balances.
  # Applies payment to statement balance first, then any remainder to current balance.
  defp calculate_payment_allocation(payment_amount, statement_balance, current_balance) do
    cond do
      # Payment covers entire statement balance with remainder
      Decimal.compare(payment_amount, statement_balance) == :gt ->
        remainder = Decimal.sub(payment_amount, statement_balance)

        {:ok,
         %{
           statement_balance: Decimal.new("0.00"),
           current_balance: Decimal.sub(current_balance, remainder),
           applied_to_statement: statement_balance,
           applied_to_current: remainder
         }}

      # Payment covers entire statement balance exactly
      Decimal.compare(payment_amount, statement_balance) == :eq ->
        {:ok,
         %{
           statement_balance: Decimal.new("0.00"),
           current_balance: current_balance,
           applied_to_statement: statement_balance,
           applied_to_current: Decimal.new("0.00")
         }}

      # Payment only partially covers statement balance
      true ->
        {:ok,
         %{
           statement_balance: Decimal.sub(statement_balance, payment_amount),
           current_balance: current_balance,
           applied_to_statement: payment_amount,
           applied_to_current: Decimal.new("0.00")
         }}
    end
  end
end
