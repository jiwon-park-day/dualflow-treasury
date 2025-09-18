defmodule DualflowTreasury.Repo.Migrations.CreateCustomers do
  use Ecto.Migration

  def change do
    create table(:customers) do
      add :company_name, :string
      add :user_name, :string
      add :password_hash, :string

      timestamps()
    end

  end
end
