defmodule PwdlessGs.Repo do
  use GenServer
  alias PwdlessGs.{Repo, UserToken}

  @topic "sync_users"
  @sync_init 1_000
  @sync_interval 30_000

  # Ets stores data as tuples. We use a record so that we can use `user(email: "toto@mail.com", token: "123")
  # Record.defrecordp(:user, key: nil, email: nil, token: nil, uuid: nil, pending_user: 0)
  #  email: nil, token: nil, uuid: nil,
  def start_link(opts) do
    {:ok, users} =
      case opts do
        [] ->
          {:ok, []}

        _ ->
          Keyword.fetch(opts, :users)
      end

    # !!! make sure to pass the `name: __MODULE__`
    GenServer.start_link(__MODULE__, users, name: __MODULE__)
  end

  def all,
    do: :ets.tab2list(:users)

  def exists?(email) do
    case find_by_email(email) do
      nil -> false
      _ -> true
    end
  end

  def pt_find_by_email(email),
    do: :persistent_term.get(email)

  def find_by_email(email),
    do: :ets.lookup(:users, email) |> List.first()

  # def find_by_token(token),
  #   do: :ets.match_object(:users, {:_, token, :_}) |> List.first()

  def find_by_id(uuid),
    do: :ets.match_object(:users, {:_, :_, uuid}) |> List.first()

  def new(email, context) do
    {:ok, token} = UserToken.generate(context, email)
    user = {email, token, Ecto.UUID.generate()}
    :ets.insert(:users, user)
    Phoenix.PubSub.broadcast_from(PwdlessGs.PubSub, self(), @topic, {:perform_new, user})
    user
  end

  def save(email, token) do
    with {^email, _, uuid} <- find_by_email(email),
         user <- {email, token, uuid} do
      :ets.insert(:users, user)
      Phoenix.PubSub.broadcast_from(PwdlessGs.PubSub, self(), @topic, {:perform_new, user})
      user
    end
  end

  @doc """
  Receives a list of users and creates a Map where keys are the users, and the values will store the authentication tokens.
  If what receives is not a list, we want it to return {:stop, "Invalid list of users"}, exiting the process and not letting the application to start.
  """
  @impl true
  def init([]) do
    with :ok <- :net_kernel.monitor_nodes(true),
         :users <- :ets.new(:users, [:set, :public, :named_table, keypos: 1]),
         :ok <- Phoenix.PubSub.subscribe(PwdlessGs.PubSub, @topic) do
      IO.inspect(Node.list([:visible, :this]), label: "Cluster:_____")
      IO.inspect("DB_init: ETS table 'users' started...")

      Process.send_after(self(), :perform_sync, @sync_init)
    end

    {:ok, []}
  end

  @impl true
  def handle_info({:nodeup, node}, _state) do
    IO.inspect("Node UP #{node}")
    {:noreply, []}
  end

  def handle_info({:nodedown, node}, state) do
    IO.inspect("Node down #{node}")
    {:noreply, state}
  end

  @impl true
  def handle_info(:perform_sync, _state) do
    # send the current node's state to other nodes
    Phoenix.PubSub.broadcast_from(PwdlessGs.PubSub, self(), @topic, {:sync, Repo.all(), self()})
    # rerun in @sync_interval
    Process.send_after(self(), :perform_sync, @sync_interval)
    {:noreply, []}
  end

  @impl true
  def handle_info({:sync, _message, from}, _state) when from == self(), do: {:noreply, []}

  def handle_info({:sync, messages, _from}, _state) do
    # IO.puts("Synced messages_______")
    :ets.insert(:users, messages)
    {:noreply, []}
  end

  @impl true
  def handle_info({:perform_new, message}, _state) do
    # IO.inspect(message, label: "New received via pubsub______")
    with {email, token, uuid} <- message do
      :ets.insert(:users, {email, token, uuid})
    end

    {:noreply, []}
  end
end

# Initial test
# def init(_), do: {:stop, "Invalid list of users"}

# @imp / l(true)
# def init(users) when is_list(users) and length(users) > 0 do
#   :ok = :net_kernel.monitor_nodes(true)

#   name = :ets.new(:users, [:set, :public, :named_table, keypos: 1])
#   IO.inspect("DB_init: ETS table #{name} started...")

#   state = Enum.reduce(users, [], &[{&1, nil, Ecto.UUID.generate(), 0} | &2])
#   :ets.insert(:users, state)

#   :ok = Phoenix.PubSub.subscribe(PwdlessGs.PubSub, @users_topic)
#   Process.send_after(self(), :perform_sync, @sync_init)
#   {:ok, state}
# end
