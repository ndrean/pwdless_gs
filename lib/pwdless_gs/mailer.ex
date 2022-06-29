defmodule PwdlessGs.Mailer do
  use Swoosh.Mailer, otp_app: :pwdless_gs

  @email_regex ~r/^[A-Za-z0-9._%+-+']+@[A-Za-z0-9.-]+\.[A-Za-z]+$/

  def valid_email?(email), do: Regex.match?(@email_regex, email)
end
