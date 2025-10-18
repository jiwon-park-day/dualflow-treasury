defmodule DualflowTreasury.Treasury do
  @moduledoc """
  Context for transaction processing and money movement.

  Handles:
  - Transaction creation and processing
  - Transfer decision algorithm
  - Daily optimization decisions
  - Transaction history and auditing


  """

  import Ecto.Query, warn: false
  require Logger
  alias DualflowTreasury.Repo
  alias DualflowTreasury.{Accounts, Billing, Customers}
  alias DualflowTreasury.Treasury.{Transaction, TransferDecision}
  alias NimbleCSV.RFC4180, as: CSV

  # Data import & parse

  def import_historical_transactions(customer_id, csv_path) do
    Repo.transaction(fn ->
      with {:ok, checking} <- Accounts.get_customer_checking_account(customer_id),
           {:ok, transaction_list} <- parse_transaction_csv(csv_path) do
        transaction_list
        |> Enum.sort_by(& &1.date)
        |> Enum.reduce_while([], fn txn_data, acc ->
          txn_data = Map.put(txn_data, :account_id, checking.id)

          case process_transaction(txn_data) do
            {:ok, txn} -> {:cont, [txn | acc]}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)
        |> case do
          {:error, reason} -> Repo.rollback(reason)
          transactions -> Enum.reverse(transactions)
        end
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  def parse_transaction_csv(csv_path) do
    transaction_list =
      csv_path
      |> File.stream!()
      |> CSV.parse_stream(skip_headers: false)

      # Skip header row
      |> Stream.drop(1)
      |> Enum.map(fn [date, amount, merchant_id, description, category, is_recurring] ->
        %{
          date: Date.from_iso8601!(date),
          amount: Decimal.new(amount),
          merchant_id: merchant_id,
          description: description,
          category: category,
          is_recurring: is_recurring == "true" || is_recurring == "TRUE"
        }
      end)
    {:ok, transaction_list}
  end

  # Transactions

  def create_transaction(attrs) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
  end

  def update_transaction_date(transaction_id, new_date) do
    case Repo.get(Transaction, transaction_id) do
      nil ->
        {:error, :transaction_not_found}

      transaction ->
        transaction
        |> Transaction.changeset(%{date: new_date})
        |> Repo.update()
    end
  end

  def process_transaction(transaction_data) do
    Repo.transaction(fn ->
      with {:ok, transaction} <- create_transaction(transaction_data),
           {:ok, _checking} <-
             Accounts.adjust_account_balance(transaction.account_id, transaction.amount),
           {:ok, _} <- maybe_process_recurring(transaction) do
        transaction
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  defp maybe_process_recurring(%{is_recurring: false}), do: {:ok, :not_recurring}

  defp maybe_process_recurring(transaction) do
    Billing.process_recurring_bill(transaction)
  end

  defp get_transaction(transaction_id) do
    case Repo.get(Transaction, transaction_id) do
      nil -> {:error, :transaction_not_found}
      transaction -> {:ok, transaction}
    end
  end

  def get_all_account_transactions(account_id) do
    transactions =
      Transaction
      |> where(account_id: ^account_id)
      |> Repo.all()

    {:ok, transactions}
  end

  def get_account_transactions_by_date_range(account_id, start_date, end_date) do
    transactions =
      Transaction
      |> where(account_id: ^account_id)
      |> where([t], t.date >= ^start_date and t.date <= ^end_date)
      |> Repo.all()

    {:ok, transactions}
  end

  def get_account_transactions_by_category(account_id, category) do
    transactions =
      Transaction
      |> where(account_id: ^account_id)
      |> where([t], t.category == ^category)
      |> Repo.all()

    {:ok, transactions}
  end

  # Transfer decisions

  def create_transfer_decision(attrs) do
    %TransferDecision{}
    |> TransferDecision.changeset(attrs)
    |> Repo.insert()
  end

  def make_daily_transfer_decision(customer_id, date) do
    with {:ok, investment} <- Accounts.get_customer_investment_account(customer_id),
         {:ok, checking} <- Accounts.get_customer_checking_account(customer_id),
         {:ok, balance} <- Accounts.get_account_balance(checking.id),
         {:ok, target_balance} <- Customers.get_customer_target_balance(customer_id),
         {:ok, predicted_bills} <- Billing.calculate_bills(checking.id, Date.add(date, 1)) do
      needed_tomorrow = Decimal.add(target_balance, predicted_bills)

      cond do
        Decimal.compare(balance, needed_tomorrow) == :gt ->
          amount = Decimal.sub(balance, needed_tomorrow)

          {:ok,
           %{
             date: date,
             amount: amount,
             needed_tomorrow: needed_tomorrow,
             predicted_bills: predicted_bills,
             target_balance: target_balance,
             from_account_id: checking.id,
             to_account_id: investment.id
           }}

        Decimal.compare(balance, needed_tomorrow) == :lt ->
          amount = Decimal.sub(needed_tomorrow, balance)

          {:ok,
           %{
             date: date,
             amount: amount,
             needed_tomorrow: needed_tomorrow,
             predicted_bills: predicted_bills,
             target_balance: target_balance,
             from_account_id: investment.id,
             to_account_id: checking.id
           }}

        Decimal.compare(balance, needed_tomorrow) == :eq ->
          {:ok, :no_transfer_needed}
      end
    end
  end

  def initiate_transfer(
        date,
        amount,
        predicted_bills_amount,
        target_balance,
        from_account_id,
        to_account_id
      ) do
    Repo.transaction(fn ->
      with {:ok, _from_account} <-
             Accounts.adjust_account_balance(from_account_id, Decimal.negate(amount)),
           {:ok, _from_transaction} <-
             create_transaction(%{
               date: date,
               amount: Decimal.negate(amount),
               merchant_id: "INTERNAL_TRANSFER",
               description: "Transfer to optimization account",
               category: "transfer",
               is_recurring: false,
               account_id: from_account_id
             }),
           # For pending
           {:ok, to_transaction} <-
             create_transaction(%{
               date: nil,
               amount: amount,
               merchant_id: "INTERNAL_TRANSFER",
               description: "Transfer from optimization",
               category: "transfer",
               is_recurring: false,
               account_id: to_account_id
             }),
           {:ok, decision} <-
             create_transfer_decision(%{
               to_account_id: to_account_id,
               from_account_id: from_account_id,
               date: date,
               amount: amount,
               predicted_bills_amount: predicted_bills_amount,
               target_balance: target_balance,
               dest_transaction_id: to_transaction.id
             }) do
        decision
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  def settle_pending_transfer(to_account_id, date, amount, dest_transaction_id) do
    Repo.transaction(fn ->
      with {:ok, _to_account} <- Accounts.adjust_account_balance(to_account_id, amount),
           {:ok, dest_transaction} <- update_transaction_date(dest_transaction_id, date) do
        dest_transaction
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end
end
