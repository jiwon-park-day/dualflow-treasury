defmodule DualflowTreasury.Simulator.Config do
  @moduledoc """
  Configuration for simulator demo settings.

  Provides hard-coded paths and customer ID for demo data.
  """

  @demo_customer_id 1
  @historical_checking_path "priv/repo/seeds/demo_user/historical_checking_transactions.csv"
  @future_checking_path "priv/repo/seeds/demo_user/future_checking_transactions.csv"
  @future_cc_path "priv/repo/seeds/demo_user/future_credit_card_transactions.csv"

  def demo_customer_id, do: @demo_customer_id
  def historical_data_path, do: @historical_checking_path
  def future_checking_path, do: @future_checking_path
  def future_cc_path, do: @future_cc_path
end
