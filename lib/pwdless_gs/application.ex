defmodule PwdlessGs.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Cluster.Supervisor, [topologies(:epmd), [name: PwdlessGs.ClusterSupervisor]]},
      PwdlessGsWeb.Telemetry,
      {Phoenix.PubSub, name: PwdlessGs.PubSub, adapter: Phoenix.PubSub.PG2},
      PwdlessGsWeb.Endpoint,
      # {PwdlessGs.Repo, []}
      {PwdlessGs.Repo, [users: testing_users()]}
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

  def topologies(key) do
    case key do
      :epmd ->
        [
          epmd_topology: [
            strategy: Cluster.Strategy.Epmd,
            config: [hosts: [:"a@127.0.0.1", :"b@127.0.0.1", :"c@127.0.0.1"]]
          ]
        ]

      :gossip ->
        [
          gossip_topology: [
            strategy: Cluster.Strategy.Gossip,
            config: [
              port: 45892,
              if_addr: "127.0.0.1",
              multicast_if: "192.168.1.1",
              multicast_addr: "233.252.1.32",
              secret: "secret"
            ]
          ]
        ]
    end
  end

  defp testing_users do
    PwdlessGs.FakeEmail.users()
  end
end
