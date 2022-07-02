defmodule PwdlessGs.Plug.Authorize do
  import Plug.Conn
  alias PwdlessGs.UserToken

  def init(opts) do
    opts
  end

  # defp bearer(conn) do
  #   with ["Bearer " <> token] <- get_req_header(conn, "authorization") do
  #     {:ok, token}
  #   else
  #     {:error, _} -> {:error, "no bearer"}
  #   end
  # end

  # can we just do "if conn.assigns[:current], do: :ok?
  def call(conn, _opts) do
    with {:header, ["Bearer " <> token]} <- {:header, get_req_header(conn, "authorization")},
         {:token, {:ok, user}} <- {:token, UserToken.verify("login", token)} do
      assign(conn, :current_user, user)
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
