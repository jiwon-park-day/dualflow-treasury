defmodule DualflowTreasury.Repo do
  use Ecto.Repo,
    otp_app: :dualflow_treasury,
    adapter: Ecto.Adapters.Postgres
end
