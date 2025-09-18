defmodule DualflowTreasury.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts" do
    field :account_type, Ecto.Enum, values: [:checking, :investment]
    field :current_balance, :decimal
    field :interest_rate, :decimal

    belongs_to :customer, DualflowTreasury.Customers.Customer

    has_many :daily_snapshots, DualflowTreasury.Accounts.AccountDailySnapshot
    has_many :interest_payments, DualflowTreasury.Accounts.InterestPayment
    has_many :transactions, DualflowTreasury.Treasury.Transaction
    has_many :recurring_bills, DualflowTreasury.Billing.RecurringBill
    has_many :to_transfer_decisions, DualflowTreasury.Treasury.TransferDecision, foreign_key: :to_account_id
    has_many :from_transfer_decisions, DualflowTreasury.Treasury.TransferDecision, foreign_key: :from_account_id

    timestamps()
  end

  def changeset(account, attrs) do
    account
    |> cast(attrs, [:account_type, :current_balance, :interest_rate, :customer_id])
    |> validate_required([:account_type, :customer_id])
    # |> validate_inclusion(:account_type, [:checking, :investment])    # Redundant with Ecto.Enum
    |> validate_number(:current_balance, greater_than_or_equal_to: 0)
    |> validate_number(:interest_rate, greater_than_or_equal_to: 0, less_than_or_equal_to: 1)
    |> foreign_key_constraint(:customer_id)
    |> unique_constraint([:customer_id, :account_type])

  end

end
