defmodule PwdlessGsWeb.Router do
  use PwdlessGsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PwdlessGsWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authorized do
    plug PwdlessGs.Plug.Authorize
  end

  scope "/", PwdlessGsWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/api", PwdlessGsWeb do
    pipe_through(:api)

    post("/session/login", SessionController, :login)
    get("/session/link/:token", SessionController, :confirm_link, params: "token")
  end

  scope "/api", PwdlessGsWeb do
    pipe_through([:api, :authorized])

    get("/users", PageController, :index)
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PwdlessGsWeb.Telemetry
    end

    scope "/dev" do
      pipe_through :browser

      # Enables the Swoosh mailbox preview in development. Note that preview only shows emails that were sent by the same node running the Phoenix server.
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
