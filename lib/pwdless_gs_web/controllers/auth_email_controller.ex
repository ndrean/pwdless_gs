defmodule PwdlessGsWeb.AuthEmailController do
  use PwdlessGsWeb, :controller

  alias PwdlessGsWeb.AuthEmail
  alias PwdlessGs.Mailer

  def send(conn, %{"email" => email} = _params, context) do
    with {:valid, true} <- {:valid, Mailer.valid_email?(email)},
         {:okToken, {:ok, token}} <- {:okToken, PwdlessGs.provide_token_for(email, context)} do
      email
      |> AuthEmail.build(token)
      |> Mailer.deliver()

      json(conn, %{message: gettext("Check your mailbox in case of successfully registered")})
    else
      {:valid, _} -> json(conn, %{message: gettext("invalid credentials")})
      {:okToken, reason} -> json(conn, %{message: reason})
    end
  end
end
