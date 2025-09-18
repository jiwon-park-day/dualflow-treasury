defmodule DualflowTreasury.Accounts.InterestPayment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "interest_payments" do
    field :payment_date, :date
    field :period_end_date, :date
    field :amount, :decimal

    belongs_to :account, DualflowTreasury.Accounts.Account
  end

  def changeset(payment, attrs) do
    payment
    |> cast(attrs, [:payment_date, :period_end_date, :amount, :account_id])
    |> validate_required([:payment_date, :period_end_date, :amount, :account_id])
    |> validate_number(:amount, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:account_id)
    |> unique_constraint([:account_id, :period_end_date])

  end

end
