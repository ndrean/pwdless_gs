defmodule PwdlessGs do
  @moduledoc """
  PwdlessGs keeps the contexts that define your domain and business logic.
  Contexts are also responsible for managing your data, regardless if it comes from the database, an external API or others.
  """
  alias PwdlessGs.{Repo, UserToken}

  def provide_token_for(email, context, repo \\ Repo)

  def provide_token_for(email, _context, _repo) when email in [nil, ""],
    do: {:error, :invalid_email}

  def provide_token_for(email, context, _repo),
    do: UserToken.generate(context, email)

  # def provide_token_for(email, context, _repo) when context in ["social_media", "login"] do
  # IO.puts("provide_token____")
  # {:ok, UserToken.generate(context, email)
  # end
end
