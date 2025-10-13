defmodule DualflowTreasury.Customers do
  @moduledoc """
  Context for customer management and authentication.

  Handles:
  - Customer authentication and registration
  - Customer settings management
  """

  import Ecto.Query, warn: false
  alias DualflowTreasury.Repo
  alias DualflowTreasury.Customers.{Customer, CustomerSettings}

  # Customer authentication

  @doc """
  Creates a new customer with hashed password.
  """
  def create_customer(attrs \\ %{}) do
    password = attrs[:password] || attrs["password"]

    attrs
    |> Map.delete(:password)
    |> Map.delete("password")
    |> Map.put(:password_hash, hash_password(password))
    |> then(&Customer.changeset(%Customer{}, &1))
    |> Repo.insert()
  end

  @doc """
  Gets a customer by ID.
  """
  def get_customer(customer_id) do
    case Repo.get(Customer, customer_id) do
      nil -> {:error, :customer_not_found}
      customer -> {:ok, customer}
    end
  end

  @doc """
  Gets a customer by username.
  """
  def get_customer_by_username(username) do
    case Repo.get_by(Customer, user_name: username) do
      nil -> {:error, :customer_not_found}
      customer -> {:ok, customer}
    end
  end

  @doc """
  Authenticates a customer with username and password.
  Returns the customer if credentials are valid.
  """
  def authenticate_customer(username, password) do
    case get_customer_by_username(username) do
      {:ok, customer} ->
        if verify_password(password, customer.password_hash) do
          {:ok, customer}
        else
          {:error, :invalid_credentials}
        end

      {:error, :customer_not_found} ->
        # Still performs hash to prevent timing attacks
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}
    end
  end

  # Customer Settings

  @doc """
  Gets customer settings by customer ID.
  """
  def get_customer_settings(customer_id) do
    case Repo.get_by(CustomerSettings, customer_id: customer_id) do
      nil -> {:error, :settings_not_found}
      settings -> {:ok, settings}
    end
  end

  @doc """
  Creates customer settings with default values.
  """
  def create_customer_settings(customer_id, attrs \\ %{}) do
    %CustomerSettings{}
    |> CustomerSettings.changeset(Map.put(attrs, :customer_id, customer_id))
    |> Repo.insert()
  end

  @doc """
  Updates customer settings.
  Creates settings with default values if they don't exist.
  """
  def update_customer_settings(customer_id, attrs) do
    case get_customer_settings(customer_id) do
      {:ok, settings} ->
        settings
        |> CustomerSettings.changeset(attrs)
        |> Repo.update()

      {:error, :settings_not_found} ->
        create_customer_settings(customer_id, attrs)
    end
  end

  @doc """
  Gets the target balance for a customer.
  Returns 0 if settings don't exist or target balance is not set.
  """
  def get_customer_target_balance(customer_id) do
    case get_customer_settings(customer_id) do
      {:ok, settings} -> {:ok, settings.target_balance || Decimal.new("0.00")}
      {:error, :settings_not_found} -> {:ok, Decimal.new("0.00")}
    end
  end

  @doc """
  Toggles the auto-transfer feature for a customer.
  Treats missing settings as having auto-transfer enabled (default true).
  """
  def toggle_customer_auto_transfer(customer_id) do
    case get_customer_settings(customer_id) do
      {:ok, settings} ->
        update_customer_settings(customer_id, %{
          auto_transfer_enabled: !settings.auto_transfer_enabled
        })

      {:error, :settings_not_found} ->
        # Settings don't exist, default is TRUE, toggling means disable
        create_customer_settings(customer_id, %{auto_transfer_enabled: false})
    end
  end

  # Password helpers

  # Hashes a password using Bcrypt.
  defp hash_password(nil), do: nil
  defp hash_password(password), do: Bcrypt.hash_pwd_salt(password)

  # Verifies a password against a hash.
  defp verify_password(password, hash), do: Bcrypt.verify_pass(password, hash)
end
