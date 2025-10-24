defmodule DualflowTreasury.Jobs.DailyTransferDecisionJob do
  @moduledoc """
  Runs at 7:00 PM MST.
  Makes transfer decisions and initiates transfers for tomorrow.
  """
  use Oban.Worker, queue: :daily_operations, max_attempts: 3

  alias DualflowTreasury.{TimeHelper, Customers, Treasury}
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{} = _job) do
    today = TimeHelper.today()
    tomorrow = TimeHelper.tomorrow()

    Logger.info("Starting daily transfer decisions for #{tomorrow}")

    {:ok, customers} = Customers.get_all_customers()

    Enum.each(customers, fn customer ->
      with {:ok, settings} <- Customers.get_customer_settings(customer.id),
           true <- settings.auto_transfer_enabled do
        case Treasury.make_daily_transfer_decision(customer.id, today) do
          {:ok, :no_transfer_needed} ->
            :ok

          {:ok, result} ->
            case Treasury.initiate_transfer(
                   result.date,
                   result.amount,
                   result.predicted_bills,
                   result.target_balance,
                   result.from_account_id,
                   result.to_account_id
                 ) do
              {:ok, _decision} ->
                :ok

              {:error, reason} ->
                Logger.error(
                  "Failed transfer decision for customer #{customer.id}: #{inspect(reason)}"
                )
            end

          {:error, reason} ->
            Logger.error(
              "Failed transfer decision for customer #{customer.id}: #{inspect(reason)}"
            )
        end
      end
    end)

    :ok
  end
end
