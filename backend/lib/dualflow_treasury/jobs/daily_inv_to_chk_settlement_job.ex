defmodule DualflowTreasury.Jobs.DailyInvToChkSettlementJob do
  @moduledoc """
  Runs at 7:00 AM MST.
  Settles INV -> CHK transfers from yesterday.
  """
  use Oban.Worker, queue: :daily_operations, max_attempts: 3

  alias DualflowTreasury.{TimeHelper, Accounts, Treasury}
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{} = _job) do
    today = TimeHelper.today()
    yesterday = TimeHelper.yesterday()

    Logger.info("Starting INV -> CHK settlement for #{yesterday}")

    {:ok, decisions} = Treasury.get_transfer_decisions_for_date(yesterday)

    Enum.each(decisions, fn decision ->
      {:ok, account_type} = Accounts.get_account_type(decision.from_account_id)
      if account_type == :investment do
          case Treasury.settle_pending_transfer(decision.to_account_id, today, decision.amount, decision.dest_transaction_id) do
            {:ok, _dest_transaction} -> :ok
            {:error, reason} -> Logger.error("Failed settlement for transfer decision #{decision.id}: #{inspect(reason)}")
          end
      end
    end)
    :ok
  end
end
