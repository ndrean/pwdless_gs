# PwdlessGs

Authentification via passwordless/email-magic-link or Social Login.
Once the email is verified (via your email account or received via a social login), you get a short term signed token and a long term signed HttpOnly cookie. Since we are working with an SSR app, we share the same domain thus cookies are applicable. The token is set in the bearer and the cookie included in the credentials. The server only decrypts the token unless it is expired, in which case the server checks for the cookie (it contains the encrypted user UUID). If it is valid, then
Authorization via a Phoenix token (with a refresher based on UUID).
Using a key/value database for storing `{email, uuid, temporary token}`

## Database choices

- Mnesia (cluster distributed)
- `:persistent_term` (cluster distributed)
- Ets distributed via Phoenix.PubSub (cluster)
- Redis as external db

Since Ets is not distributed, we need to somehow distribute the data through the cluster. The Phoenix pubsub service is distributed, thus we can use it to update the local Ets table of each connected node. The notification service defaults to PG2, the in-build Erlang solution. We can also choose Redis.

## Automatic clustering

With `libcluster`, you have a "ip" dicovery with `epmd` and a "DNS" discovery with  `gossip`.

> `gossip` didn't work for me with Phoenix ??

What about [Docker and EPMD?](https://www.jkmrto.dev/posts/erlang-distributed-with-docker-and-libcluster)

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
> PORT=4000 iex --name a@127.0.0.1 --cookie 'secret' -S mix phx.server
> PORT=4001 iex --name b@127.0.0.1 --cookie 'secret' -S mix phx.server
```

## Misc Elixir functions

```iex
# check GenServer state:
iex> :sys.get_state(PwdlessGs.Repo)

# check Ets database
iex> :ets.tab2list(:users)

# RPC calls from one node to the other
iex> state = :rpc.call(:"a@127.0.0.1", PwdlessGs.Repo, :all, [])
```
