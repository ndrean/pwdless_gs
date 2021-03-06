defmodule PwdlessGs.Plug.Authorize do
  import Plug.Conn
  alias PwdlessGs.{UserToken}
  import Phoenix.Controller, only: [json: 2]

  def init(opts) do
    opts[:blacklist]
  end

  defp read_bearer(conn, blacklist) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization") do
      if token not in blacklist,
        do: {:ok, token},
        else: {:error, :forbidden}
    end
  end

  def call(conn, opts) do
    with {:header, {:ok, token}} <- {:header, read_bearer(conn, opts)},
         {:token, {:ok, user}} <- {:token, UserToken.verify("login", token)} do
      conn
      |> assign(:current_user, user)
    else
      {:token, {:error, :invalid}} ->
        Plug.Conn.put_status(conn, :unauthorized)
        |> json(%{message: "401", other: "invalid"})

      {:token, {:error, :expired}} ->
        # with %{"refresher" => %{user_id: id}} <- fetch_cookies(conn, encrypted: ~w(refresher)),
        #  {user, _, ^id} <- Repo.find_by_id(id) do
        conn
        |> Plug.Conn.put_status(401)
        |> json(%{message: "Dear , please renew credentials to continue"})
        |> halt()

      # end

      {:header, {:error, reason}} ->
        conn
        |> Plug.Conn.put_status(401)
        |> Phoenix.Controller.json(%{message: "401", other: reason})
        |> halt()
    end
  end
end
