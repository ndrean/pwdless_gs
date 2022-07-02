# PwdlessGs

[Source Oauth](https://github.com/auth0-developer-hub/api_phoenix_elixir_hello-world/tree/basic-authorization)

[Rate limiting GenServer](https://akoutmos.com/post/rate-limiting-with-genservers/)

## Git: move modifications to a new branch

Create a new feature branch and move the uncommitted work to the new branch. Moreover, the master branch shouldn't be modified.

```bash
git switch -C new-branch
git status
# Changes not staged
git add . && git commit -m 'modifications'

# return to main
git switch main
git status
# nothing to commit !!!! YES !!
```

## Settings to distribute

- Run `mix phx.gen.secret` to get a secret_key_base

- set the PORT to an env variable:

```iex
config :pwdless_gs, PwdlessGsWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: System.get_env("PORT")],
  secret_key_base: "e+6Qd+yFSxCY26rpVkCwMyhaE+T3yxjNVZKPiMKJaqlou6OaVyoLaE5kWItqUOcB",
```

- setup `libcluster` with `EPMD` strategy

- run in two separate terminals

```bash
> PORT=4000 iex --name a@127.0.0.1 -S mix phx.server
> PORT=4001 iex --name b@127.0.0.1 -S mix phx.server
```

## RPC calls

```iex
state = :rpc.call(:"a@127.0.0.1", PwdlessGs.Repo, :all, [])
```
