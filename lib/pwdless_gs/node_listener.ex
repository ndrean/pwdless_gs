defmodule PwdlessGs.NodeListener do
  use GenServer
  require Logger
  alias PwdlessGs.Repo
  @sync_init 3_000
  @topic "sync_users"

  def start_link(_opts \\ []),
    do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @impl true
  def init([]) do
    :ok = :net_kernel.monitor_nodes(true)
    # :ok = Phoenix.PubSub.subscribe(PwdlessGs.PubSub, @topic)

    {:ok, nil}
  end

  @impl true
  def handle_info({:nodeup, node}, _state) do
    Logger.info("Node UP #{node}")
    IO.inspect(Node.list([:visible, :this]), label: "Cluster_____:")
    Process.send_after(self(), {:perform_sync, []}, @sync_init)
    {:noreply, nil}
  end

  @impl true
  def handle_info({:nodedown, node}, _state) do
    Logger.info("Node down #{node}")
    {:noreply, nil}
  end

  @impl true
  def handle_info({:perform_sync, []}, _state) do
    :ok = Phoenix.PubSub.broadcast_from(PwdlessGs.PubSub, self(), @topic, {:sync, Repo.all()})
    {:noreply, nil}
  end
end
