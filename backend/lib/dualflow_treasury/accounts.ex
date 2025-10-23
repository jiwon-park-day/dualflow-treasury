defmodule DualflowTreasury.Accounts do
  @moduledoc """
  Context for account and financial state management.

  Handles:
  - Account operations
  - Daily compound interest calculations
  - Daily account snapshots
  - Monthly interest payment processing
  """

  import Ecto.Query, warn: false
  require Logger
  alias DualflowTreasury.Repo
  alias DualflowTreasury.Accounts.{Account, AccountDailySnapshot, InterestPayment}

  # Account CRUD

  # Creates a new account with the given attributes.
  defp create_account(attrs) do
    %Account{}
    |> Account.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates both investment and checking accounts for a customer.
  """
  def create_customer_accounts(customer_id) do
    with {:ok, investment} <- create_customer_investment_account(customer_id),
         {:ok, checking} <- create_customer_checking_account(customer_id) do
      {:ok, %{investment: investment, checking: checking}}
    end
  end

  @doc """
  Creates an investment account with 5.00% APY.
  """
  def create_customer_investment_account(customer_id) do
    investment_attrs = %{
      customer_id: customer_id,
      account_type: :investment,
      interest_rate: Decimal.new("0.05")
    }

    create_account(investment_attrs)
  end

  @doc """
  Creates a checking account with 2.50% APY.
  """
  def create_customer_checking_account(customer_id) do
    checking_attrs = %{
      customer_id: customer_id,
      account_type: :checking,
      interest_rate: Decimal.new("0.025")
    }

    create_account(checking_attrs)
  end

  # Updates an account's attributes.
  defp update_account(account_id, attrs) do
    with {:ok, account} <- get_account(account_id) do
      account
      |> Account.changeset(attrs)
      |> Repo.update()
    end
  end

  @doc """
  Updates an account's balance to a new value.
  """
  def update_account_balance(account_id, new_balance) do
    update_account(account_id, %{current_balance: new_balance})
  end

  @doc """
  Adjusts an account's balance by the given amount.
  Amount can be positive (credit) or negative (debit).
  """
  def adjust_account_balance(account_id, adjustment_amount) do
    with {:ok, account} <- get_account(account_id) do
      new_balance = Decimal.add(account.current_balance, adjustment_amount)
      update_account(account_id, %{current_balance: new_balance})
    end
  end

  @doc """
  Gets an account by ID.
  """
  def get_account(account_id) do
    case Repo.get(Account, account_id) do
      nil -> {:error, :account_not_found}
      account -> {:ok, account}
    end
  end

  @doc """
  Gets both accounts for a customer.

  Each customer has exactly one of each account type.
  """
  def get_customer_accounts(customer_id) do
    with {:ok, investment} <- get_customer_investment_account(customer_id),
         {:ok, checking} <- get_customer_checking_account(customer_id) do
      {:ok, %{investment: investment, checking: checking}}
    end
  end

  @doc """
  Gets the investment account for a customer.
  """
  def get_customer_investment_account(customer_id) do
    case Repo.one(
           Account
           |> where(customer_id: ^customer_id, account_type: :investment)
         ) do
      nil -> {:error, :investment_account_not_found}
      account -> {:ok, account}
    end
  end

  @doc """
  Gets the checking account for a customer.
  """
  def get_customer_checking_account(customer_id) do
    case Repo.one(
           Account
           |> where(customer_id: ^customer_id, account_type: :checking)
         ) do
      nil -> {:error, :checking_account_not_found}
      account -> {:ok, account}
    end
  end

  @doc """
  Gets the account type for an account.
  """
  def get_account_type(account_id) do
    with {:ok, account} <- get_account(account_id) do
      {:ok, account.account_type}
    end
  end

  @doc """
  Gets the current balance for an account.
  """
  def get_account_balance(account_id) do
    with {:ok, account} <- get_account(account_id) do
      {:ok, account.current_balance}
    end
  end

  @doc """
  Gets the interest rate for an account.
  """
  def get_account_interest_rate(account_id) do
    with {:ok, account} <- get_account(account_id) do
      {:ok, account.interest_rate}
    end
  end

  # Interest calculations

  # Calculates daily compound interest for a specific date.
  # Interest is compounded daily based on:
  # - Current ending balance
  # - Cumulative interest from previous day
  # - Annual interest rate divided by 365
  defp calculate_account_daily_interest(account_id, date) do
    with {:ok, ending_balance} <- get_account_balance(account_id),
         # Cumulative interest until date - 1
         {:ok, cumulative_interest} <-
           get_account_cumulative_interest(account_id, Date.add(date, -1)),
         {:ok, interest_rate} <- get_account_interest_rate(account_id) do
      daily_interest =
        ending_balance
        |> Decimal.add(cumulative_interest)
        |> Decimal.mult(interest_rate)
        |> Decimal.div(365)

      {:ok, daily_interest}
    end
  end

  # Gets cumulative interest for a specific date.
  # Returns 0 if snapshot doesn't exist.
  defp get_account_cumulative_interest(account_id, date) do
    case get_account_daily_snapshot(account_id, date) do
      {:ok, snapshot} ->
        {:ok, snapshot.cumulative_interest}

      {:error, :snapshot_not_found} ->
        {:ok, Decimal.new("0.00")}
    end
  end

  # Daily snapshots

  # Creates a snapshot record in the database.
  defp create_snapshot(attrs) do
    %AccountDailySnapshot{}
    |> AccountDailySnapshot.changeset(attrs)
    |> Repo.insert()
  end

  # Gets a daily snapshot by snapshot ID.
  defp get_daily_snapshot(snapshot_id) do
    case Repo.get(AccountDailySnapshot, snapshot_id) do
      nil -> {:error, :snapshot_not_found}
      snapshot -> {:ok, snapshot}
    end
  end

  @doc """
  Gets a daily snapshot by account ID and date.
  """
  def get_account_daily_snapshot(account_id, date) do
    case Repo.get_by(AccountDailySnapshot, %{account_id: account_id, date: date}) do
      nil -> {:error, :snapshot_not_found}
      snapshot -> {:ok, snapshot}
    end
  end

  @doc """
  Creates a daily account snapshot for a specific date.

  Called at midnight (date + 1) when the ending balance is finalized.
  Cumulative interest resets to 0 on the 1st of each month after payment processing.
  """
  def create_account_daily_snapshot(account_id, date) do
    with {:ok, balance} <- get_account_balance(account_id),
         {:ok, daily_interest} <- calculate_account_daily_interest(account_id, date) do
      prev_cumulative =
        if date.day == 1 do
          period_end_date = Date.add(date, -1)

          case get_account_interest_payment(account_id, period_end_date) do
            # Payment processed - reset monthly cumulative
            {:ok, _payment} ->
              Decimal.new("0.00")

            # Payment not processed - carry forward cumulative
            {:error, :payment_not_found} ->
              Logger.warning(
                "Interest payment not found for account #{account_id}, period #{period_end_date}. Carrying forward cumulative."
              )

              with {:ok, amount} <- get_account_cumulative_interest(account_id, period_end_date) do
                amount
              end
          end
        else
          # Add previous day's cumulative interest for normal days
          with {:ok, amount} <- get_account_cumulative_interest(account_id, Date.add(date, -1)) do
            amount
          end
        end

      snapshot_attrs = %{
        date: date,
        ending_balance: balance,
        interest_earned: daily_interest,
        cumulative_interest: Decimal.add(prev_cumulative, daily_interest),
        account_id: account_id
      }

      create_snapshot(snapshot_attrs)
    end
  end

  # Monthly interest payments

  # Creates an interest payment record in the database.
  defp create_interest_payment(attrs) do
    %InterestPayment{}
    |> InterestPayment.changeset(attrs)
    |> Repo.insert()
  end

  # Gets an interest payment record for a specific period.
  # Used to verify payment was processed before resetting cumulative interest.
  defp get_account_interest_payment(account_id, period_end_date) do
    case Repo.get_by(InterestPayment, %{account_id: account_id, period_end_date: period_end_date}) do
      nil -> {:error, :payment_not_found}
      payment -> {:ok, payment}
    end
  end

  @doc """
  Gets all interest payments for an account within a date range.
  Returns a list of interest payment records.
  """
  def get_account_interest_payments(account_id, start_date, end_date) do
    payments =
      InterestPayment
      |> where(account_id: ^account_id)
      |> where([p], p.period_end_date >= ^start_date and p.period_end_date <= ^end_date)
      |> Repo.all()

    {:ok, payments}
  end

  @doc """
  Processes monthly interest payment for an account.

  Adds cumulative interest from the period end date to the account balance and creates a payment record.
  Must be called on the 1st of the month after period end date's snapshot is posted.

  ## Example
      process_account_monthly_interest_payment(123, ~D[2025-09-30], ~D[2025-10-01])
  """
  def process_account_monthly_interest_payment(account_id, period_end_date, payment_date) do
    if payment_date.day != 1 do
      {:error, :not_first_day_of_month}
    else
      Repo.transaction(fn ->
        with {:ok, cumulative_interest} <-
               get_account_cumulative_interest(account_id, period_end_date),
             {:ok, _account} <- adjust_account_balance(account_id, cumulative_interest),
             {:ok, payment} <-
               create_interest_payment(%{
                 payment_date: payment_date,
                 period_end_date: period_end_date,
                 amount: cumulative_interest,
                 account_id: account_id
               }) do
          payment
        else
          {:error, reason} -> Repo.rollback(reason)
        end
      end)
    end
  end
end
