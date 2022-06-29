defmodule PwdlessGsWeb.PageController do
  use PwdlessGsWeb, :controller

  def index(conn, params) do
    users = PwdlessGs.Repo.all()
    json(conn, %{users: users})
    # conn
    # |> assign(:token, Map.get(params, "token", ""))
    # |> render("index.html")
  end
end
