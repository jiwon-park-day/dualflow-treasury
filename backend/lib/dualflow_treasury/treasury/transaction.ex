defmodule DualflowTreasury.Treasury.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transactions" do
    field :date, :date
    field :amount, :decimal   # Negative: outgoing, Positive: incoming
    field :merchant_id, :string
    field :description, :string
    field :category, :string
    field :is_recurring, :boolean, default: false

    belongs_to :account, DualflowTreasury.Accounts.Account

    has_one :transfer_decision, DualflowTreasury.Treasury.TransferDecision, foreign_key: :dest_transaction_id
    has_one :bill_history, DualflowTreasury.Billing.RecurringBillHistory
  end

  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:date, :amount, :merchant_id, :description, :category, :is_recurring, :account_id])
    |> validate_required([:amount, :merchant_id, :account_id])   # Pending transactions don't have dates
    |> validate_number(:amount, not_equal_to: 0)
    |> validate_length(:merchant_id, min: 1)
    |> foreign_key_constraint(:account_id)
  end

end
