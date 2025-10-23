defmodule DualflowTreasury.Jobs.DailyInterestJob do
  @moduledoc """
  Runs at 12:00 AM MST.
  Calculates interest for yesterday and creates daily snapshots.
  """

  use Oban.Worker, queue: :daily_operations, max_attempts: 3

  alias DualflowTreasury.{TimeHelper, Accounts}
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{} = _job) do
    yesterday = TimeHelper.yesterday()

    Logger.info("Starting daily interest calculation for #{yesterday}")

    {:ok, accounts} = Accounts.get_all_accounts()

    Enum.each(accounts, fn account ->
      case Accounts.create_account_daily_snapshot(account.id, yesterday) do
        {:ok, _snapshot} -> :ok
        {:error, reason} -> Logger.error("Failed snapshot for account #{account.id}: #{inspect(reason)}")
      end
    end)
    :ok
  end
end
