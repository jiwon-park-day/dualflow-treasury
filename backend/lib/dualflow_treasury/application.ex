defmodule DualflowTreasury.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DualflowTreasuryWeb.Telemetry,
      DualflowTreasury.Repo,
      {DNSCluster, query: Application.get_env(:dualflow_treasury, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: DualflowTreasury.PubSub},
      # Start a worker by calling: DualflowTreasury.Worker.start_link(arg)
      # {DualflowTreasury.Worker, arg},
      # Start to serve requests, typically the last entry
      DualflowTreasuryWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DualflowTreasury.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DualflowTreasuryWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
