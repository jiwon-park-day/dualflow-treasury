defmodule DualflowTreasury.Repo.Migrations.CreateCreditCardTransactions do
  use Ecto.Migration

  def change do
    create table(:credit_card_transactions) do
      add :credit_card_id, references(:credit_cards, on_delete: :delete_all), null: false
      add :amount, :decimal, precision: 12, scale: 2
      add :description, :string
      add :transaction_date, :date, null: false
      add :category, :string
    end

    create index(:credit_card_transactions, [:credit_card_id])
    create index(:credit_card_transactions, [:credit_card_id, :transaction_date])
    create index(:credit_card_transactions, [:credit_card_id, :category])

  end
end
