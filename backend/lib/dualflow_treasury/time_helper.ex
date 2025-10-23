defmodule DualflowTreasury.TimeHelper do
  @moduledoc """
  Timezone utilities for the DualflowTreasury application.

  All business logic operates in Mountain Time (America/Denver).
  Use these helpers to get consistent "today" and "yesterday" dates
  across jobs, simulators, and business logic.
  """

  @timezone "America/Denver"

  @doc """
  Gets the current date in MST/MDT timezone.

  Use this in jobs and simulators to get a consistent "today".

  ## Examples

      iex> DualflowTreasury.TimeHelper.today()
      ~D[2025-10-22]
  """
  def today do
    DateTime.now!(@timezone) |> DateTime.to_date()
  end

  @doc """
  Gets yesterday's date in MST/MDT timezone.

  ## Examples

      iex> # If today is 2025-10-22
      iex> DualflowTreasury.TimeHelper.yesterday()
      ~D[2025-10-21]
  """
  def yesterday do
    Date.add(today(), -1)
  end

  @doc """
  Gets tomorrow's date in MST/MDT timezone.

  ## Examples

      iex> # If today is 2025-10-22
      iex> DualflowTreasury.TimeHelper.tomorrow()
      ~D[2025-10-23]
  """
  def tomorrow do
    Date.add(today(), 1)
  end

  @doc """
  Gets the timezone string used by the application.

  ## Examples

      iex> DualflowTreasury.TimeHelper.timezone()
      "America/Denver"
  """
  def timezone do
    @timezone
  end

end
