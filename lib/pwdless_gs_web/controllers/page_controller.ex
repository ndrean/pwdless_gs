defmodule PwdlessGsWeb.PageController do
  use PwdlessGsWeb, :controller

  def index(conn, _params) do
    users = PwdlessGs.Repo.all()
    result = Enum.reduce(users, [], &[%{id: elem(&1, 2), user: elem(&1, 0)} | &2])
    json(conn, %{users: result})
  end
end
