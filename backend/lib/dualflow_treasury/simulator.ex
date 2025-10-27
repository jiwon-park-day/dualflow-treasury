defmodule DualflowTreasury.Simulator do
  @moduledoc """
  Context for demo data injection and fast-forward utilities.

  Handles:
  - Transaction dataset loading and parsing
  - Transaction injection from CSV datasets
  - Fast-forward simulation for demos

  """

  alias DualflowTreasury.Repo
  alias DualflowTreasury.{Accounts, Treasury, CreditCards}
  alias NimbleCSV.RFC4180, as: CSV
  require Logger

  # Import & parse

  @doc """
  Imports checking transactions from a CSV file.

  Loads all transactions from the CSV without filtering by date.
  Returns a list of transaction maps ready for injection.

  ## Example
      Simulator.import_checking_transactions("priv/simulation_data/checking.csv")

  """
  def import_checking_transactions(csv_path) do
    transactions =
      csv_path
      |> File.stream!()
      |> CSV.parse_stream(skip_headers: false)
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

    {:ok, transactions}
  end

  @doc """
  Imports credit card transactions from a CSV file.

  Loads all transactions from the CSV without filtering by date.
  Returns a list of transaction maps ready for injection.

  ## Example
      Simulator.import_credit_card_transactions("priv/simulation_data/credit_card.csv")

  """
  def import_credit_card_transactions(csv_path) do
    transactions =
      csv_path
      |> File.stream!()
      |> CSV.parse_stream(skip_headers: false)
      |> Stream.drop(1)
      |> Enum.map(fn [date, amount, description, category] ->
        %{
          transaction_date: Date.from_iso8601!(date),
          amount: Decimal.new(amount),
          description: description,
          category: category
        }
      end)

    {:ok, transactions}
  end

  @doc """
  Imports checking transactions for a specific date from a CSV file.

  Filters transactions by date during CSV parsing.
  Useful for daily injection jobs that process transactions one day at a time.

  ## Example
      Simulator.import_checking_transactions_for_date("priv/simulation_data/checking.csv", ~D[2025-01-15])

  """
  def import_checking_transactions_for_date(csv_path, date) do
    transactions =
      csv_path
      |> File.stream!()
      |> CSV.parse_stream(skip_headers: false)
      |> Stream.drop(1)
      |> Enum.filter(fn [txn_date | _] ->
        Date.from_iso8601!(txn_date) == date
      end)
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

    {:ok, transactions}
  end

  @doc """
  Imports credit card transactions for a specific date from a CSV file.

  Filters transactions by date during CSV parsing.
  Useful for daily injection jobs that process transactions one day at a time.

  ## Example
      Simulator.import_credit_card_transactions_for_date("priv/simulation_data/credit_card.csv", ~D[2025-01-15])

  """
  def import_credit_card_transactions_for_date(csv_path, date) do
    transactions =
      csv_path
      |> File.stream!()
      |> CSV.parse_stream(skip_headers: false)
      |> Stream.drop(1)
      |> Enum.filter(fn [txn_date | _] ->
        Date.from_iso8601!(txn_date) == date
      end)
      |> Enum.map(fn [date, amount, description, category] ->
        %{
          transaction_date: Date.from_iso8601!(date),
          amount: Decimal.new(amount),
          description: description,
          category: category
        }
      end)

    {:ok, transactions}
  end

  @doc """
  Imports historical transactions from a CSV file.

  Processes transactions chronologically.
  All transactions are wrapped in a single database transaction for atomicity.

  ## Example
      Simulator.import_historical_transactions(customer_id, "priv/repo/seeds/demo_user/historical_checking_transactions.csv")

  """
  def import_historical_transactions(customer_id, csv_path) do
    Repo.transaction(fn ->
      with {:ok, checking} <- Accounts.get_customer_checking_account(customer_id),
           {:ok, transaction_list} <- import_checking_transactions(csv_path) do
        transaction_list
        |> Enum.sort(fn t1, t2 -> Date.compare(t1.date, t2.date) != :gt end)
        |> Enum.reduce_while([], fn txn_data, acc ->
          txn_data = Map.put(txn_data, :account_id, checking.id)

          case Treasury.process_transaction(txn_data) do
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

  # Transaction injection

  @doc """
  Injects checking transactions for a specific date.

  Filters the provided transaction list for transactions matching the date, then processes each transaction through Treasury.process_transaction/1.

  """
  def inject_checking_transaction(customer_id, transaction_list, date) do
    with {:ok, checking} <- Accounts.get_customer_checking_account(customer_id) do
      todays_transactions =
        Enum.filter(transaction_list, fn txn ->
          txn.date == date
        end)

      results =
        Enum.reduce_while(todays_transactions, [], fn txn_data, acc ->
          txn_data = Map.put(txn_data, :account_id, checking.id)

          case Treasury.process_transaction(txn_data) do
            {:ok, txn} -> {:cont, [txn | acc]}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)

      case results do
        {:error, reason} -> {:error, reason}
        transactions -> {:ok, Enum.reverse(transactions)}
      end
    end
  end

  @doc """
  Injects credit card transactions for a specific date.

  Filters the provided transaction list for transactions matching the date, then processes each transaction through CreditCards.process_credit_card_transaction/1.

  """
  def inject_credit_card_transaction(customer_id, transaction_list, date) do
    with {:ok, credit_card} <- CreditCards.get_customer_credit_card(customer_id) do
      todays_transactions =
        Enum.filter(transaction_list, fn txn ->
          txn.transaction_date == date
        end)

      results =
        Enum.reduce_while(todays_transactions, [], fn txn_data, acc ->
          txn_data = Map.put(txn_data, :credit_card_id, credit_card.id)

          case CreditCards.process_credit_card_transaction(txn_data) do
            {:ok, txn} -> {:cont, [txn | acc]}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)

      case results do
        {:error, reason} -> {:error, reason}
        transactions -> {:ok, Enum.reverse(transactions)}
      end
    end
  end

  # Fast-forward

  @doc """
  Fast-forwards simulation from start_date to end_date.

  Executes all system jobs and injects transactions in chronological order without waiting for actual time to pass. Simulates the entire treasury
  management system including:
  - Daily interest calculations and snapshots
  - Monthly interest payments
  - Transfer decisions and settlements
  - Transaction injections
  - Credit card payments and statement closings

  ## Job Execution Order (per day)
  - 12:00 AM: Daily interest calculation and snapshot creation (for yesterday)
  - 1:00 AM: Monthly interest payment (1st of month only)
  - 7:00 AM: INV → CHK transfer settlement (from yesterday's decision)
  - 8:00 AM: Transaction injection (checking and credit card)
  - 9:00 AM: Automatic credit card payment (10th of month only)
  - 7:00 PM: Transfer decision and initiation (for tomorrow)
  - 10:00 PM: CHK → INV transfer settlement (from today's decision)
  - 11:59 PM: Credit card statement closing (15th of month only)

  """
  def fast_forward_to_date(
        customer_id,
        start_date,
        end_date,
        checking_csv_path,
        credit_card_csv_path
      ) do
    with {:ok, accounts} <- Accounts.get_customer_accounts(customer_id),
         {:ok, credit_card} <- CreditCards.get_customer_credit_card(customer_id),
         {:ok, checking_txn} <- import_checking_transactions(checking_csv_path),
         {:ok, credit_card_txn} <- import_credit_card_transactions(credit_card_csv_path) do
      Logger.info("Fast-forwarding from #{start_date} to #{end_date}...")

      Date.range(start_date, end_date)
      |> Enum.each(fn date ->
        today = date
        yesterday = Date.add(date, -1)

        # Daily interest job (12 AM)
        unless today == start_date do
          Accounts.create_account_daily_snapshot(accounts.investment.id, yesterday)
          Accounts.create_account_daily_snapshot(accounts.checking.id, yesterday)
        end

        # Monthly interest payment (1st 1 AM)
        if today.day == 1 && today != start_date do
          Accounts.process_account_monthly_interest_payment(
            accounts.investment.id,
            yesterday,
            today
          )

          Accounts.process_account_monthly_interest_payment(
            accounts.checking.id,
            yesterday,
            today
          )
        end

        # Daily next-day settlement INV -> CHK (7 AM)
        case Treasury.get_customer_transfer_decisions(customer_id, yesterday, yesterday) do
          {:ok, []} ->
            :no_decision

          {:ok, [decision]} ->
            if decision.to_account_id == accounts.checking.id do
              Treasury.settle_pending_transfer(
                decision.to_account_id,
                today,
                decision.amount,
                decision.dest_transaction_id
              )
            end
        end

        # Transaction injection (8 AM)
        inject_checking_transaction(customer_id, checking_txn, today)
        inject_credit_card_transaction(customer_id, credit_card_txn, today)

        # Monthly credit card payment (10th 9 AM)
        if today.day == 10 do
          CreditCards.process_automatic_credit_card_payment(credit_card.id, today)
        end

        # Daily transfer decision (7 PM)
        case Treasury.make_daily_transfer_decision(customer_id, today) do
          {:ok, :no_transfer_needed} ->
            :no_transfer

          {:ok, result} ->
            Treasury.initiate_transfer(
              result.date,
              result.amount,
              result.predicted_bills,
              result.target_balance,
              result.from_account_id,
              result.to_account_id
            )
        end

        # Daily same-day settlement CHK -> INV (10 PM)
        case Treasury.get_customer_transfer_decisions(customer_id, today, today) do
          {:ok, []} ->
            :no_decision

          {:ok, [decision]} ->
            if decision.to_account_id == accounts.investment.id do
              Treasury.settle_pending_transfer(
                decision.to_account_id,
                today,
                decision.amount,
                decision.dest_transaction_id
              )
            end
        end

        # Monthly credit card statement closing (15th 11:59 PM)
        if today.day == 15 do
          CreditCards.process_statement_closing(credit_card.id)
        end
      end)

      {:ok, :fast_forward_complete}
    end
  end
end
