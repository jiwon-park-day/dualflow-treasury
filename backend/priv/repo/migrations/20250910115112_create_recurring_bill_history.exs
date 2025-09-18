defmodule DualflowTreasury.Repo.Migrations.CreateRecurringBillHistory do
  use Ecto.Migration

  def change do
    create table(:recurring_bill_history) do
      add :bill_id, references(:recurring_bills, on_delete: :delete_all), null: false
      add :actual_amount, :decimal, precision: 12, scale: 2, null: false
      add :predicted_amount, :decimal, precision: 12, scale: 2  # Nullable for new bills
      add :prediction_error, :decimal, precision: 12, scale: 2  # Nullable for new bills
      add :transaction_id, references(:transactions, on_delete: :nilify_all)   # Nullable: nilify_all

      timestamps(updated_at: false)

    end

    create index(:recurring_bill_history, [:bill_id])
    create index(:recurring_bill_history, [:transaction_id])

  end
end
