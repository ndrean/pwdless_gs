defmodule PwdlessGsWeb.AuthEmail do
  use Phoenix.Swoosh, view: PwdlessGsWeb.AuthEmailView

  @from "support@PwdlessGs.com"

  def build(email, token) do
    # url = auth_email_url(PwdlessGsWeb.Endpoint, :show, [], token: token)
    # new()
    %Swoosh.Email{}
    |> to(email)
    |> from(@from)
    |> subject("Log in to Passwordless")
    |> assign(:token, token)
    |> render_body("login_link.html")
  end
end
