defmodule PwdlessGs.UserToken do
  @moduledoc """
  A config with a secret key has created in config and generate by "mix phx.gen.secret'
  The module provides 2 inverse functions, generate and verify.
  """
  alias Phoenix.Token

  @secret Application.get_env(:pwdless_gs, __MODULE__)[:secret_key_base]
  @max_social_age 86400
  # no token will be decrypted if issued Time.now() - max_magic_age
  @max_magic_age 60

  @doc """
  Generates a token from the context and data. If the context is:
  - "magic-link" builds a short term token from the user email that expires in @max_magic_age.
  - "social-media" or "login" builds a Long Term token with an expiration of @max_social_age
  """

  def generate("magic_link", data) do
    {:ok, Token.sign(@secret, "magic_link", data, max_age: @max_magic_age)}
    #  signed_at: System.system_time(:second),
  end

  def generate(context, data) when context in ["social_media", "login"] do
    {:ok, Token.sign(@secret, context, data, max_age: @max_social_age)}
  end

  def generate(_context, data) when data in [nil, ""], do: {:error, :invalid}

  def generate_long(context, id) when context in ["social_media", "login"] do
    Token.sign(@secret, context, id, max_age: @max_social_age + 60)
  end

  def verify(context, token, data, _max_age \\ @max_social_age)
      when context in ["social_link", "login"] do
    IO.puts("VERIFIY____")

    case Token.verify(@secret, context, token) do
      {:ok, ^data} ->
        {:ok, data}

      {:ok, _other} ->
        {:error, :invalid}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def verify("magic_link", token) do
    case Token.verify(@secret, "magic_link", token, max_age: @max_magic_age) do
      {:ok, data} -> {:ok, data}
      {:error, reason} -> {:error, reason}
    end
  end

  def verify(context, token) when context in ["social_media", "login"] do
    case Token.verify(@secret, "login", token, max_age: @max_social_age) do
      {:ok, user} -> {:ok, user}
      {:error, reason} -> {:error, reason}
    end
  end
end
