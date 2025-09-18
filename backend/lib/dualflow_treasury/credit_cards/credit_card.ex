defmodule DualflowTreasury.CreditCards.CreditCard do
  use Ecto.Schema
  import Ecto.Changeset

  schema "credit_cards" do
    field(:card_name, :string)
    field(:current_balance, :decimal)
    field(:statement_balance, :decimal)
    field(:credit_limit, :decimal)
    field(:statement_closing_day, :integer)
    field(:payment_due_day, :integer)
    field(:min_payment, :decimal)
    field(:apr, :decimal)

    belongs_to(:customer, DualflowTreasury.Customers.Customer)

    has_many(:transactions, DualflowTreasury.CreditCards.CreditCardTransaction)
  end

  def changeset(card, attrs) do
    card
    |> cast(attrs, [
      :card_name,
      :current_balance,
      :statement_balance,
      :credit_limit,
      :statement_closing_day,
      :payment_due_day,
      :min_payment,
      :apr,
      :customer_id
    ])
    |> validate_required([:credit_limit, :statement_closing_day, :payment_due_day, :customer_id])
    |> validate_number(:credit_limit, greater_than_or_equal_to: 0)
    |> validate_number(:statement_closing_day, greater_than: 0, less_than_or_equal_to: 31)
    |> validate_number(:payment_due_day, greater_than: 0, less_than_or_equal_to: 31)
    |> validate_min_payment()
    |> validate_apr()
    |> foreign_key_constraint(:customer_id)
    |> unique_constraint(:customer_id)
  end

  defp validate_min_payment(changeset) do
    case get_field(changeset, :min_payment) do
      nil -> changeset
      amount -> validate_number(changeset, :min_payment, greater_than_or_equal_to: 0)
    end
  end

  defp validate_apr(changeset) do
    case get_field(changeset, :apr) do
      nil -> changeset
      apr -> validate_number(changeset, :apr, greater_than_or_equal_to: 0, less_than_or_equal_to: 1)
    end
  end
end
