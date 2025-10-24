defmodule DualflowTreasury.Jobs.MonthlyStatementClosingJob do
  @moduledoc """
  Runs at 11:59 PM MST on the 15th of each month.
  Processes credit card statement closing for all cards.
  """

  use Oban.Worker

  alias DualflowTreasury.{TimeHelper, CreditCards}
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{} = _job) do
    today = TimeHelper.today()

    Logger.info("Starting credit card statement closing processing for #{today}")

    if today.day != 15 do
      Logger.error("Credit card statement closing ran on wrong day: #{today}")
    else
      {:ok, credit_cards} = CreditCards.get_all_credit_cards()
      Enum.each(credit_cards, fn credit_card ->
        case CreditCards.process_statement_closing(credit_card.id) do
          {:ok, _card} -> :ok
          {:error, reason} -> Logger.error("Failed credit card statement closing for card #{credit_card.id}: #{inspect(reason)}")
        end
      end)
    end
    :ok
  end
end
