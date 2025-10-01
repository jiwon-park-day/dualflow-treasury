defmodule DualflowTreasury.Customers do
  @moduledoc """
  Context for customer management and settings.
  """

  import Ecto.Query, warn: false
  alias DualflowTreasury.Repo
  alias DualflowTreasury.Customers.{Customer, CustomerSettings}

  # Customer

  def create_customer(attrs \\ %{}) do
    password = attrs[:password] || attrs["password"]

    attrs
    |> Map.delete(:password)
    |> Map.delete("password")
    |> Map.put(:password_hash, hash_password(password))
    |> then(&Customer.changeset(%Customer{}, &1))
    |> Repo.insert()
  end

  def get_customer(id), do: Repo.get(Customer, id)

  def get_customer_by_username(username) do
    Repo.get_by(Customer, user_name: username)
  end

  def authenticate_customer(username, password) do
    case get_customer_by_username(username) do
      nil -> {:error, :invalid_credentials}
      customer ->
        if verify_password(password, customer.password_hash) do
          {:ok, customer}
        else
          {:error, :invalid_credentials}
        end
    end
  end

  # Customer Settings

  def get_customer_settings(customer_id) do
    Repo.get_by(CustomerSettings, customer_id: customer_id)
  end

  def create_customer_settings(customer_id, attrs \\ %{}) do
    %CustomerSettings{}
    |> CustomerSettings.changeset(Map.put(attrs, :customer_id, customer_id))
    |> Repo.insert()
  end

  def update_settings(customer_id, attrs) do
    case get_customer_settings(customer_id) do
      nil -> create_customer_settings(customer_id, attrs)
      settings ->
        settings
        |> CustomerSettings.changeset(attrs)
        |> Repo.update()
    end
  end

  def get_target_balance(customer_id) do
    case get_customer_settings(customer_id) do
      nil -> Decimal.new(0)
      settings -> settings.target_balance || Decimal.new(0)
    end
  end

  def toggle_auto_transfer(customer_id) do
    settings = get_customer_settings(customer_id)
    current = if settings, do: settings.auto_transfer_enabled, else: true
    update_settings(customer_id, %{auto_transfer_enabled: !current})
  end

  # Helpers

  defp hash_password(nil), do: nil
  defp hash_password(password), do: Bcrypt.hash_pwd_salt(password)

  defp verify_password(password, hash), do: Bcrypt.verify_pass(password, hash)
end
