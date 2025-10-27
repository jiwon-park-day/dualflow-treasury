defmodule DualflowTreasury.Simulator.Jobs.TransactionInjectionJob do
  @moduledoc """
  Runs at 9:00 AM MST.
  Injects checking account and credit card transactions for demo simulation.
  """

  use Oban.Worker, queue: :simulation, max_attempts: 3

  alias DualflowTreasury.{TimeHelper, Simulator}
  alias DualflowTreasury.Simulator.Config
  require Logger

  # Demo settings

  @impl Oban.Worker
  def perform(%Oban.Job{} = _job) do
    today = TimeHelper.today()

    demo_customer_id = Config.demo_customer_id()
    future_checking_path = Config.future_checking_path()
    future_cc_path = Config.future_cc_path()

    Logger.info("Starting transaction injection for #{today}")

    with {:ok, checking_txns} <-
           Simulator.import_checking_transactions_for_date(future_checking_path, today),
         {:ok, credit_card_txns} <-
           Simulator.import_credit_card_transactions_for_date(future_cc_path, today),
         {:ok, _checking_results} <-
           Simulator.inject_checking_transaction(demo_customer_id, checking_txns, today),
         {:ok, _credit_card_results} <-
           Simulator.inject_credit_card_transaction(demo_customer_id, credit_card_txns, today) do
      :ok
    else
      {:error, reason} -> Logger.error("Failed demo transaction injection: #{inspect(reason)}")
    end
    :ok
  end
end
