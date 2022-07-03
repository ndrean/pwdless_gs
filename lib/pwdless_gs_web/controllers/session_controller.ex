defmodule PwdlessGsWeb.SessionController do
  use PwdlessGsWeb, :controller

  alias PwdlessGs.{Repo, Mailer, UserToken}
  alias PwdlessGsWeb.AuthEmailController

  def login(conn, %{"email" => email} = params) do
    case Mailer.valid_email?(email) do
      true ->
        if Repo.find_by_email(email) do
          AuthEmailController.send(conn, params, "magic_link")
        else
          signup(conn, params)
        end

      false ->
        json(conn, %{message: gettext("Invalid email")})
    end
  end

  def signup(conn, %{"email" => email} = params) do
    Repo.new(email, "magic_link")
    AuthEmailController.send(conn, params, "magic_link")
  end

  # plug.conn encode / decode cookie
  def confirm_link(conn, %{"token" => token} = _params) do
    case UserToken.verify("magic_link", token) do
      {:ok, email} ->
        # provide a longer term token
        {:ok, session_token} = PwdlessGs.provide_token_for(email, "login")
        {^email, ^session_token, uuid, _time} = Repo.save(email, session_token)

        # assign a verfiy long term cookie
        conn
        |> assign(:token, token)
        |> assign(:current, email)
        |> PwdlessGs.provide_cookie_for(uuid)
        |> tap(fn conn ->
          %{"refresher" => %{user_id: value}} =
            fetch_cookies(conn, encrypted: ~w(refresher)).cookies

          IO.puts("[TODO]: push the session token and the cookie to the client via websocket")
          IO.inspect(value, label: "cookie")
        end)
        |> tap(fn conn -> IO.inspect(conn.assigns, label: "assigns") end)
        |> tap(fn conn -> IO.inspect(conn.cookies, label: "cookies") end)

        json(conn, %{
          message: gettext("Welcome ") <> "#{email}!",
          session_token: session_token,
          refresher_cookie: uuid
        })

      {:error, :expired} ->
        json(conn, %{
          message: gettext("The link expired", action: "The link is expired, please renew it")
        })

      {:error, :invalid} ->
        json(conn, %{message: "corrupted"})

      {:error, reason} ->
        json(conn, %{message: reason})
    end
  end
end
