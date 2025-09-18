defmodule DualflowTreasury.Billing.RecurringBill do
  use Ecto.Schema
  import Ecto.Changeset

  schema "recurring_bills" do
    field :merchant_id, :string
    field :description, :string
    field :predicted_amount, :decimal
    field :monthly_due_day, :integer
    field :is_active, :boolean, default: true

    belongs_to :account, DualflowTreasury.Accounts.Account

    has_many :bill_history, DualflowTreasury.Billing.RecurringBillHistory, foreign_key: :bill_id

    timestamps()
  end

  def changeset(bill, attrs) do
    bill
    |> cast(attrs, [:merchant_id, :description, :predicted_amount, :monthly_due_day, :is_active, :account_id])
    |> validate_required([:merchant_id, :predicted_amount, :monthly_due_day, :account_id])
    |> validate_number(:predicted_amount, greater_than: 0)
    |> validate_number(:monthly_due_day, greater_than: 0, less_than_or_equal_to: 31)
    |> validate_length(:merchant_id, min: 1)
    |> foreign_key_constraint(:account_id)
  end

end
