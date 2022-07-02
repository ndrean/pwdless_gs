defmodule PwdlessGsWeb.PageController do
  use PwdlessGsWeb, :controller

  def index(conn, _params) do
    users = PwdlessGs.Repo.all()
    # transform [{email, token uuid}, {_,_,_}...] in [[%{id: uuuid, user, email},...]
    result = Enum.reduce(users, [], &[%{id: elem(&1, 2), user: elem(&1, 0)} | &2])
    json(conn, %{current: conn.assigns[:current], users: result})
  end
end
