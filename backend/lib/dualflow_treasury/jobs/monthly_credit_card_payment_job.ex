defmodule DualflowTreasury.Jobs.MonthlyCreditCardPaymentJob do
  @moduledoc """
  Runs at 9:00 AM MST on the 10th of each month.
  Processes automatic credit card payments for all cards.
  """

  use Oban.Worker

  alias DualflowTreasury.{TimeHelper, CreditCards}
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{} = _job) do
    today = TimeHelper.today()

    Logger.info("Starting credit card payment processing for #{today}")

    if today.day != 10 do
      Logger.error("Credit card payment ran on wrong day: #{today}")
    else
      {:ok, credit_cards} = CreditCards.get_all_credit_cards()
      Enum.each(credit_cards, fn credit_card ->
        case CreditCards.process_automatic_credit_card_payment(credit_card.id, today) do
          {:ok, :no_payment_needed} -> :ok
          {:ok, _transaction} -> :ok
          {:error, reason} -> Logger.error("Failed credit card payment for card #{credit_card.id}: #{inspect(reason)}")
        end
      end)
    end
    :ok
  end
end
