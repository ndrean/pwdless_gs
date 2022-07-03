defmodule PwdlessGs.Repo do
  use GenServer
  alias PwdlessGs.{Repo, UserToken}
  alias :ets, as: Ets

  require Logger
  @topic "sync_users"
  @sync_init 3_000
  # @sync_interval 30_000

  # Ets stores data as tuples. We use a record so that we can use `user(email: "toto@mail.com", token: "123")
  # Record.defrecordp(:user, key: nil, email: nil, token: nil, uuid: nil, pending_user: 0)
  #  email: nil, token: nil, uuid: nil,
  def start_link(_opts) do
    # !!! make sure to pass the `name: __MODULE__`
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
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
    do: Ets.lookup(:users, email) |> List.first()

  # def find_by_token(token),
  #   do: :ets.match_object(:users, {:_, token, :_}) |> List.first()

  def find_by_id(uuid),
    do: Ets.match_object(:users, {:_, :_, uuid, :_}) |> List.first()

  def new(email, context) do
    {:ok, token} = UserToken.generate(context, email)
    user = {email, token, Ecto.UUID.generate(), :os.system_time()}
    GenServer.cast(__MODULE__, {:perform_new, user})
    user
  end

  def save(email, token) do
    with {^email, _, uuid, _} <- find_by_email(email) do
      user = {email, token, uuid, :os.system_time()}
      GenServer.cast(__MODULE__, {:perform_new, user})
      user
    end
  end

  @doc """
  Receives a list of users and creates a Map where keys are the users, and the values will store the authentication tokens.
  If what receives is not a list, we want it to return {:stop, "Invalid list of users"}, exiting the process and not letting the application to start.
  """
  @impl true
  def init([]) do
    # nb: returns the previous state
    false = Process.flag(:trap_exit, true)
    :ok = :net_kernel.monitor_nodes(true)
    :users = Ets.new(:users, [:set, :public, :named_table, keypos: 1])
    :ok = Phoenix.PubSub.subscribe(PwdlessGs.PubSub, @topic)

    Logger.info("ETS table 'users' started...")

    {:ok, []}
  end

  @impl true
  def handle_cast({:perform_new, message}, _state) do
    Ets.insert(:users, message)
    Logger.debug("[R]")
    Phoenix.PubSub.broadcast_from(PwdlessGs.PubSub, self(), @topic, {:new, message})
    {:noreply, []}
  end

  @impl true
  def handle_info({:new, message}, _state) do
    IO.puts("New received via pubsub______")
    Ets.insert(:users, message)
    Logger.debug("[R]")
    {:noreply, []}
  end

  @impl true
  def handle_info({:nodeup, node}, _state) do
    Logger.info("Node UP #{node}")
    IO.inspect(Node.list([:visible, :this]), label: "Cluster_____:")
    Process.send_after(self(), {:perform_sync, []}, @sync_init)
    {:noreply, []}
  end

  @impl true
  def handle_info({:nodedown, node}, state) do
    Logger.info("Node down #{node}")
    {:noreply, state}
  end

  @impl true
  def handle_info({:perform_sync, []}, _state) do
    :ok = Phoenix.PubSub.broadcast_from(PwdlessGs.PubSub, self(), @topic, {:sync, Repo.all()})
    {:noreply, []}
  end

  @impl true
  def handle_info({:sync, messages}, _state) do
    IO.puts("Synced messages_______")
    Ets.insert(:users, messages)
    Logger.debug("[R]")
    {:noreply, []}
  end

  @impl true
  def terminate(reason, state) do
    Phoenix.PubSub.unsubscribe(PwdlessGs.Repo, @topic)
    Ets.delete(:users)
    {:stop, reason, state}
  end
end
