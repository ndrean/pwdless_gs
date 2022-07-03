defmodule PwdlessGs do
  import Plug.Conn, only: [put_resp_cookie: 4]

  @moduledoc """
  PwdlessGs keeps the contexts that define your domain and business logic.
  Contexts are also responsible for managing your data, regardless if it comes from the database, an external API or others.
  """
  alias PwdlessGs.UserToken

  def provide_token_for(email, _context) when email in [nil, ""],
    do: {:error, :invalid_email}

  def provide_token_for(email, context),
    do: UserToken.generate(context, email)

  def provide_cookie_for(conn, uuid) do
    conn
    |> put_resp_cookie("refresher", %{user_id: uuid},
      encrypt: true,
      http_only: true,
      max_age: 2_600_000
    )
  end
end
