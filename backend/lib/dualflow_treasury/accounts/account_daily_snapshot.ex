defmodule DualflowTreasury.Accounts.AccountDailySnapshot do
  use Ecto.Schema
  import Ecto.Changeset

  schema "account_daily_snapshots" do
    field(:date, :date)
    field(:ending_balance, :decimal)
    field(:interest_earned, :decimal)
    field(:cumulative_interest, :decimal)

    belongs_to :account, DualflowTreasury.Accounts.Account
  end

  def changeset(snapshot, attrs) do
    snapshot
    |> cast(attrs, [:date, :ending_balance, :interest_earned, :cumulative_interest, :account_id])
    |> validate_required([
      :date,
      :ending_balance,
      :interest_earned,
      :cumulative_interest,
      :account_id
    ])
    |> validate_number(:ending_balance, greater_than_or_equal_to: 0)
    |> validate_number(:interest_earned, greater_than_or_equal_to: 0)
    |> validate_number(:cumulative_interest, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:account_id)
    |> unique_constraint([:account_id, :date])
  end
end
