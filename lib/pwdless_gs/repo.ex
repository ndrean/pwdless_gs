defmodule PwdlessGs.Repo do
  @moduledoc """
  Ets stores data as a list of tuples. A client session is: `{email, token, uuid, time_stamp}`. Wwe sync all Ets on "nodeup".

  """
  use GenServer
  require Logger
  alias :ets, as: Ets
  alias PwdlessGs.{Repo, UserToken}

  @topic "sync_users"
  @sync_init 3_000

  def start_link(opts) do
    {:ok, users} =
      case opts do
        [] -> {:ok, []}
        _ -> Keyword.fetch(opts, :users)
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
  Instanciate an `epmd` listener, and subscribe to a PubSub topic.
  """
  @impl true
  def init(users) do
    # nb: returns the previous state
    false = Process.flag(:trap_exit, true)
    :ok = :net_kernel.monitor_nodes(true)
    :users = Ets.new(:users, [:set, :public, :named_table, keypos: 1])
    Ets.insert(:users, users)
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
