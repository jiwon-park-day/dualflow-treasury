defmodule DualflowTreasury.Customers.Customer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "customers" do
    field :company_name, :string
    field :user_name, :string
    field :password_hash, :string

    has_one :customer_settings, DualflowTreasury.Customers.CustomerSettings
    has_many :accounts, DualflowTreasury.Accounts.Account
    has_one :credit_card, DualflowTreasury.CreditCards.CreditCard

    timestamps()
  end

  def changeset(customer, attrs) do
    customer
    |> cast(attrs, [:company_name, :user_name, :password_hash])
    |> validate_required([:company_name, :user_name, :password_hash])
    |> validate_length(:user_name, min: 3)
    |> unique_constraint(:user_name)
  end

end
