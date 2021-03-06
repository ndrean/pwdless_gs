defmodule PwdlessGs.PwdlessGsTest do
  use ExUnit.Case, async: true

  alias PwdlessGs.Repo

  describe "provide_token_for/2" do
    test "returns error when email is blank" do
      assert {:error, :invalid_email} = Pwdless_gs.provide_token_for(nil)
      assert {:error, :invalid_email} = Pwdless_gs.provide_token_for("")
    end

    test "returns error when email does not exist" do
      repo = :"repo_test_#{__MODULE__}_1"
      email = "foo@test.com"
      {:ok, _pid} = Repo.start_link(name: repo, emails: [email])

      assert {:error, :not_found} = Pwdless_gs.provide_token_for(repo, "not-found-email@test.com")
    end

    test "returns token when valid email" do
      repo = :"repo_test_#{__MODULE__}_2"
      email = "foo@test.com"
      {:ok, _pid} = Repo.start_link(name: repo, emails: [email])

      assert {:ok, token} = Pwdless_gs.provide_token_for(repo, email)
      assert byte_size(token) > 0
    end
  end

  describe "verify_token/2" do
    test "returns error when token not found" do
      repo = :"repo_test_#{__MODULE__}_3"
      email = "foo@test.com"
      {:ok, _pid} = Repo.start_link(name: repo, emails: [email])
      {:ok, _token} = Pwdless_gs.provide_token_for(repo, email)

      assert {:error, :not_found} = Pwdless_gs.verify_token(repo, "not-found-token")
    end

    test "returns value when token valid" do
      repo = :"repo_test_#{__MODULE__}_4"
      email = "foo@test.com"
      {:ok, _pid} = Repo.start_link(name: repo, emails: [email])
      {:ok, token} = Pwdless_gs.provide_token_for(repo, email)

      assert {:ok, ^email} = Pwdless_gs.verify_token(repo, token)
    end
  end
end
