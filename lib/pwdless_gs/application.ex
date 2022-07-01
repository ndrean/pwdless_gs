defmodule PwdlessGs.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      PwdlessGsWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: PwdlessGs.PubSub},
      # Start the Endpoint (http/https)
      PwdlessGsWeb.Endpoint,
      # {PwdlessGs.Repo, []}
      {PwdlessGs.Repo, [users: users()]}
      # Start a worker by calling: PwdlessGs.Worker.start_link(arg)
      # {PwdlessGs.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PwdlessGs.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PwdlessGsWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def users do
    ["toto@mail.com", "bibi@mail.com"]
  end
end
