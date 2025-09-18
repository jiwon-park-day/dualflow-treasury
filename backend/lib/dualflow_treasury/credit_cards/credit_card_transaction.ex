defmodule DualflowTreasury.CreditCards.CreditCardTransaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "credit_card_transactions" do
    field :amount, :decimal
    field :description, :string
    field :transaction_date, :date
    field :category, :string

    belongs_to :credit_card, DualflowTreasury.CreditCards.CreditCard
  end

  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:amount, :description, :transaction_date, :category, :credit_card_id])
    |> validate_required([:amount, :transaction_date, :credit_card_id])
    |> validate_number(:amount, not_equal_to: 0)
    |> foreign_key_constraint(:credit_card_id)
  end

end
