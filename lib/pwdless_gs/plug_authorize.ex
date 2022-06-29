defmodule PwdlessGs.Plug.Authorize do
  import Plug.Conn
  alias PwdlessGs.UserToken

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    with {:header, ["Bearer " <> token]} <- {:header, get_req_header(conn, "authorization")},
         {:token, {:ok, user}} <- {:token, UserToken.verify("login", token)} do
      conn
      |> assign(:email, user)
    else
      {:header, _} ->
        {:error, "no bearer"}

      {:token, {:error, reason}} ->
        conn
        |> Plug.Conn.put_status(401)
        |> Phoenix.Controller.json(%{message: "401", other: reason})
        |> halt()
    end
  end
end
