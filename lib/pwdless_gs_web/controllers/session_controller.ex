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
        {:ok, session_token} = UserToken.generate("login", email)
        {^email, ^session_token, uuid} = Repo.save(email, session_token)

        # assign a verfiy long term cookie
        conn
        |> assign(:token, token)
        |> assign(:current, email)
        |> put_resp_cookie("refresher", %{user_id: uuid},
          encrypt: true,
          http_only: true,
          max_age: 2_600_000
        )
        |> tap(fn conn ->
          %{"refresher" => %{user_id: value}} =
            fetch_cookies(conn, encrypted: ~w(refresher)).cookies

          IO.inspect(value, label: "cookie")
        end)

        json(conn, %{
          message: gettext("Welcome ") <> "#{email}!",
          session_token: session_token,
          refresher: uuid
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
