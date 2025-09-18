defmodule DualflowTreasury.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    # Create enum for account types
    execute "CREATE TYPE account_type AS ENUM ('checking', 'investment')", "DROP TYPE account_type"
    create table(:accounts) do
      add :customer_id, references(:customers, on_delete: :delete_all), null: false
      add :account_type, :account_type, null: false
      add :current_balance, :decimal, precision: 12, scale: 2, default: 0.00
      add :interest_rate, :decimal, precision: 5, scale: 4

      timestamps()
    end

    create index(:accounts, [:customer_id])
    create unique_index(:accounts, [:customer_id, :account_type])

  end
end
