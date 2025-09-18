defmodule DualflowTreasury.Treasury.TransferDecision do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transfer_decisions" do
    field :date, :date
    field :amount, :decimal
    field :predicted_bills_amount, :decimal
    field :target_balance, :decimal

    belongs_to :from_account, DualflowTreasury.Accounts.Account
    belongs_to :to_account, DualflowTreasury.Accounts.Account
    belongs_to :dest_transaction, DualflowTreasury.Treasury.Transaction
  end

  def changeset(decision, attrs) do
    decision
    |> cast(attrs, [:date, :amount, :predicted_bills_amount, :target_balance, :from_account_id, :to_account_id, :dest_transaction_id])
    |> validate_required([:date, :amount, :predicted_bills_amount, :target_balance, :from_account_id, :to_account_id, :dest_transaction_id])
    |> validate_number(:amount, greater_than: 0)  # Always transfer positive amount from/to accounts
    |> validate_number(:predicted_bills_amount, greater_than_or_equal_to: 0)
    |> validate_number(:target_balance, greater_than_or_equal_to: 0)
    |> validate_different_accounts()
    |> foreign_key_constraint(:from_account_id)
    |> foreign_key_constraint(:to_account_id)
    |> foreign_key_constraint(:dest_transaction_id)
    |> unique_constraint(:dest_transaction_id)  # 1 to 1
    |> unique_constraint([:date, :from_account_id])
    |> unique_constraint([:date, :to_account_id])
  end

  defp validate_different_accounts(changeset) do
    from_account_id = get_field(changeset, :from_account_id)
    to_account_id = get_field(changeset, :to_account_id)

    if from_account_id && to_account_id && from_account_id == to_account_id do
      add_error(changeset, :to_account_id, "cannot be same as from_account")
    else
      changeset
    end
  end

end
