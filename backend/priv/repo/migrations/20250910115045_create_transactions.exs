defmodule DualflowTreasury.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :account_id, references(:accounts, on_delete: :delete_all), null: false
      add :date, :date  # Nullable for pending transactions
      add :amount, :decimal, precision: 12, scale: 2
      add :merchant_id, :string, null: false
      add :description, :string
      add :category, :string    # Application-level validation (Ecto.Enum)
      add :is_recurring, :boolean, default: false
    end

    create index(:transactions, [:account_id])
    create index(:transactions, [:account_id, :date])
    create index(:transactions, [:account_id, :merchant_id])
    create index(:transactions, [:account_id, :category])
    create index(:transactions, [:account_id, :is_recurring])

  end
end
