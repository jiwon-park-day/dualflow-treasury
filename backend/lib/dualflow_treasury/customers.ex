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
  Creates a new customer with hashed password and default settings.

  The password is automatically hashed before storage.
  """
  def create_customer(attrs) do
    password = attrs[:password] || attrs["password"]

    customer_attrs =
      attrs
      |> Map.delete(:password)
      |> Map.delete("password")
      |> Map.put(:password_hash, hash_password(password))

    Repo.transaction(fn ->
      with {:ok, customer} <- Customer.changeset(%Customer{}, customer_attrs) |> Repo.insert(),
           {:ok, _settings} <- create_customer_settings(customer.id) do
        customer
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
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


  # Password helpers

  # Hashes a password using Bcrypt.
  defp hash_password(nil), do: nil
  defp hash_password(password), do: Bcrypt.hash_pwd_salt(password)

  # Verifies a password against a hash.
  defp verify_password(password, hash), do: Bcrypt.verify_pass(password, hash)


  # Customer Settings

  # Creates customer settings with default values.
  defp create_customer_settings(customer_id) do
    %CustomerSettings{}
    |> CustomerSettings.changeset(%{customer_id: customer_id})
    |> Repo.insert()
  end

  # Updates customer settings' attributes.
  defp update_customer_settings(customer_id, attrs) do
    with {:ok, settings} <- get_customer_settings(customer_id) do
      settings
      |> CustomerSettings.changeset(attrs)
      |> Repo.update()
      end
  end

  @doc """
  Updates a customer's target balance.
  """
  def update_customer_target_balance(customer_id, new_target_balance) do
    update_customer_settings(customer_id, %{target_balance: new_target_balance})
  end

  @doc """
  Toggles the auto-transfer feature for a customer.
  """
  def toggle_customer_auto_transfer(customer_id) do
    with {:ok, settings} <- get_customer_settings(customer_id) do
      update_customer_settings(customer_id, %{auto_transfer_enabled: !settings.auto_transfer_enabled})
    end
  end

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
  Gets the target balance for a customer.
  Returns 0 if settings don't exist or target balance is not set.
  """
  def get_customer_target_balance(customer_id) do
    case get_customer_settings(customer_id) do
      {:ok, settings} -> {:ok, settings.target_balance || Decimal.new("0.00")}
      {:error, :settings_not_found} -> {:ok, Decimal.new("0.00")}
    end
  end
end
