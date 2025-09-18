defmodule DualflowTreasury.Repo.Migrations.CreateAccountDailySnapshots do
  use Ecto.Migration

  def change do
    create table(:account_daily_snapshots) do
      add :account_id, references(:accounts, on_delete: :delete_all), null: false
      add :date, :date, null: false
      add :ending_balance, :decimal, precision: 12, scale: 2
      add :interest_earned, :decimal, precision: 12, scale: 2
      add :cumulative_interest, :decimal, precision: 12, scale: 2
    end

    create index(:account_daily_snapshots, [:account_id])
    create unique_index(:account_daily_snapshots, [:account_id, :date])

  end
end
