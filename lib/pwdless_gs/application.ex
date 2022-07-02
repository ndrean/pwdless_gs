defmodule PwdlessGs.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PwdlessGsWeb.Telemetry,
      {Phoenix.PubSub, name: PwdlessGs.PubSub},
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

  def testing_users do
    ["toto@mail.com", "bibi@mail.com"]
  end
end
