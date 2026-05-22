defmodule Accountkit.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    :ok = Accountkit.RateLimit.init_policy_cache()

    children = [
      AccountkitWeb.Telemetry,
      Accountkit.Repo,
      {DNSCluster, query: Application.get_env(:accountkit, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Accountkit.PubSub},
      # Start a worker by calling: Accountkit.Worker.start_link(arg)
      # {Accountkit.Worker, arg},
      # Start to serve requests, typically the last entry
      AccountkitWeb.Endpoint,
      {AshAuthentication.Supervisor, [otp_app: :accountkit]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Accountkit.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AccountkitWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
