defmodule DualflowTreasury.Repo.Migrations.CreateTransferDecisions do
  use Ecto.Migration

  def change do
    create table(:transfer_decisions) do
      add :from_account_id, references(:accounts, on_delete: :delete_all), null: false
      add :to_account_id, references(:accounts, on_delete: :delete_all), null: false
      add :date, :date, null: false
      add :amount, :decimal, precision: 12, scale: 2
      add :predicted_bills_amount, :decimal, precision: 12, scale: 2
      add :target_balance, :decimal, precision: 12, scale: 2
      add :dest_transaction_id, references(:transactions, on_delete: :nilify_all)
    end

    create index(:transfer_decisions, [:from_account_id])
    create index(:transfer_decisions, [:to_account_id])
    create unique_index(:transfer_decisions, [:from_account_id, :date])   # One transfer per day
    create unique_index(:transfer_decisions, [:to_account_id, :date])   # One transfer per day
    create unique_index(:transfer_decisions, [:dest_transaction_id])

  end
end
