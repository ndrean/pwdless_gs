defmodule PwdlessGs.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Cluster.Supervisor, [topologies(), [name: PwdlessGs.ClusterSupervisor]]},
      PwdlessGsWeb.Telemetry,
      {Phoenix.PubSub, name: PwdlessGs.PubSub, adapter: Phoenix.PubSub.PG2},
      PwdlessGsWeb.Endpoint,
      {PwdlessGs.Repo, []}
      # {PwdlessGs.Repo, [users: testing_users()]}
    ]

    opts = [strategy: :one_for_one, name: PwdlessGs.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PwdlessGsWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp topologies do
    [
      epmd_topology: [
        strategy: Cluster.Strategy.Epmd,
        config: [hosts: [:"a@127.0.0.1", :"b@127.0.0.1"]]
      ]
    ]
  end

  defp testing_users do
    ["toto@mail.com", "bibi@mail.com"]
  end
end
