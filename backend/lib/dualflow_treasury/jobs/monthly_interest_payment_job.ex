defmodule DualflowTreasury.Jobs.MonthlyInterestPaymentJob do
  @moduledoc """
  Runs at 1:00 AM MST on the 1st of each month.
  Processes monthly interest payments for all accounts.
  """

  use Oban.Worker

  alias DualflowTreasury.{TimeHelper, Accounts}
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{} = _job) do
    today = TimeHelper.today()
    yesterday = TimeHelper.yesterday()

    Logger.info("Starting monthly interest payment processing for period ending #{yesterday}")

    if today.day != 1 do
      Logger.error("Monthly interest ran on wrong day: #{today}")
    else
      {:ok, accounts} = Accounts.get_all_accounts()
      Enum.each(accounts, fn account ->
        case Accounts.process_account_monthly_interest_payment(account.id, yesterday, today) do
          {:ok, _payment} -> :ok
          {:error, reason} -> Logger.error("Failed interest payment for account #{account.id}: #{inspect(reason)} ")
        end
      end)
    end
    :ok
  end
end
