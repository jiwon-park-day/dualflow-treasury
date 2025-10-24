defmodule DualflowTreasury.Jobs.DailyChkToInvSettlementJob do
  @moduledoc """
  Runs at 10:00 PM MST.
  Settles CHK -> INV transfers from today.
  """
  use Oban.Worker, queue: :daily_operations, max_attempts: 3

  alias DualflowTreasury.{TimeHelper, Accounts, Treasury}
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{} = _job) do
    today = TimeHelper.today()

    Logger.info("Starting CHK -> INV settlement for #{today}")

    {:ok, decisions} = Treasury.get_transfer_decisions_for_date(today)

    Enum.each(decisions, fn decision ->
      {:ok, account_type} = Accounts.get_account_type(decision.from_account_id)
      if account_type == :checking do
          case Treasury.settle_pending_transfer(decision.to_account_id, today, decision.amount, decision.dest_transaction_id) do
            {:ok, _dest_transaction} -> :ok
            {:error, reason} -> Logger.error("Failed settlement for transfer decision #{decision.id}: #{inspect(reason)}")
          end
      end
    end)
    :ok
  end
end
