# defmodule PwdlessGs.Repo do
#   use GenServer
#   alias PwdlessGs.UserToken
#   # alias PwdlessGs.Db
#   # alias Phoenix.PubSub
#   require Record

#   @users_topic "sync_users"
#   @sync_interval 1000

#   # Ets stores data as tuples. We use a record so that we can use `user(email: "toto@mail.com", token: "123")
#   Record.defrecordp(:user, key: nil, email: nil, token: nil, uuid: nil, pending_user: 0)

#   def all(),
#     do: :sys.get_state(__MODULE__)

#   def find_by_email(email),
#     do: Enum.find(all(), &(elem(&1, 0) == email))

#   def find_by_token(token),
#     do: Enum.find(all(), &(elem(&1, 1) == token))

#   def find_by_id(uuid),
#     do: Enum.find(all(), &(elem(&1, 2) == uuid))

#   # _____
#   def start_link(opts) do
#     {:ok, users} =
#       case opts do
#         [] -> {:ok, []}
#         _ -> Keyword.fetch(opts, :users)
#       end

#     GenServer.start_link(__MODULE__, users, opts)
#   end

#   def new(email, context, pid \\ __MODULE__),
#     do: GenServer.call(pid, {:new, email, context})

#   def save(email, token, pid \\ __MODULE__) do
#     {^email, _, uuid} = find_by_email(email)
#     GenServer.call(pid, {:save, email, token, uuid})
#   end

#   # ______________________
#   @doc """
#   Receives a list of users and creates a Map where keys are the users, and the values will store the authentication tokens.
#   If what receives is not a list, we want it to return {:stop, "Invalid list of users"}, exiting the process and not letting the application to start.
#   """
#   @impl true
#   def init([]) do
#     # name = :ets.new(:users, [:set, :public, :named_table, keypos: user(:key) + 1])
#     # IO.inspect("DB_init: ETS table #{name} started...")

#     # :ok = PubSub.subscribe(PwdlessGs.PubSub, @users_topic)
#     # {:messages, [{:sync, new_state, _pid}]} = Process.info(self(), :messages)
#     {:ok, []}
#   end

#   @impl true
#   def init(users) when is_list(users) and length(users) > 0 do
#     state = Enum.reduce(users, [], &[{:user, &1, nil, Ecto.UUID.generate()} | &2])
#     # name = :ets.new(:users, [:set, :public, :named_table, keypos: user(:key) + 1])
#     # IO.inspect("DB_init: ETS table #{name} started...")

#     # Enum.each(state, fn user -> :ets.insert(:users, {:user}) end)
#     # :ets.insert(:users, state)
#     # Db.init(name: :users, pos: user(:key) + 1)
#     # :ok = PubSub.subscribe(PwdlessGs.PubSub, @users_topic)
#     # Process.send_after(self(), :perform_sync, @sync_interval)
#     IO.inspect(users)
#     {:ok, state}
#   end

#   @impl true
#   def handle_info(:perform_sync, state) do
#     :ok = PubSub.broadcast(PwdlessGs.PubSub, @users_topic, {:sync, state, self()})
#     {:messages, [{:sync, new_state, _pid}]} = Process.info(self(), :messages)
#     IO.inspect(new_state, label: "from pubsub______")
#     # Process.send_after(self(), :perform_sync, @sync_interval)
#     {:noreply, new_state}
#   end

#   def handle_info({:sync, users, from}, state) when from == self(),
#     do: {:noreply, state}

#   def handle_info({:sync, users, _from}, state) do
#     Enum.each(users, fn {key, pending_users} ->
#       nil
#       # :ets.update_counter():users, key, {user()}, user(key: key, pending_user: 0))
#     end)

#     {:reply, state}
#   end

#   # catch all
#   def handle_info(info, state) do
#     IO.inspect(info, label: "_______________________________________")
#     {:noreply, state}
#   end

#   @impl true

#   def handle_call({:all}, _from, state) do
#     {:reply, :sys.get_state(PwdlessGs.Repo), state}
#   end

#   def handle_call({:new, email, context}, _from, state) do
#     {:ok, token} = UserToken.generate(context, email)
#     state = [{email, token, Ecto.UUID.generate()} | state]
#     # :ets.update_counter(:users, )
#     {:reply, state, state}
#   end

#   def handle_call({:save, email, session_token, uuid}, _from, state) do
#     # :ok = PubSub.broadcast(PwdlessGs.PubSub, @users_topic, {:sync, state, self()})

#     Process.send(self(), :update, user(email: email, token: session_token, uuid: uuid))
#     state = List.keyreplace(state, email, 0, {email, session_token, uuid})
#     {:reply, {email, session_token, uuid}, state}
#   end

#   # catch all
#   # def handle_info({:update, users, from}, state) do
#   #   IO.inspect("sent")
#   #   {:noreply, state}
#   # end
# end
