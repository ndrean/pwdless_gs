defmodule PwdlessGs.Repo do
  use GenServer
  alias PwdlessGs.UserToken

  def start_link(opts) do
    {:ok, users} =
      case opts do
        [] ->
          {:ok, []}

        _ ->
          Keyword.fetch(opts, :users)
      end

    GenServer.start_link(__MODULE__, users, name: __MODULE__)
  end

  def all(pid \\ __MODULE__),
    do: GenServer.call(pid, {:all})

  def new(email, context, pid \\ __MODULE__),
    do: GenServer.call(pid, {:new, email, context})

  # def exists?(email, pid \\ __MODULE__),
  #   do: GenServer.call(pid, {:exists, email})

  def save(email, token, pid \\ __MODULE__) do
    {^email, _, uuid} = find_by_email(email)
    GenServer.call(pid, {:save, email, token, uuid})
  end

  def find_by_email(email, pid \\ __MODULE__) do
    GenServer.call(pid, {:find_by_email, email})
  end

  def find_by_token(token, pid \\ __MODULE__),
    do: GenServer.call(pid, {:find_by_token, token})

  def find_by_id(uuid, pid \\ __MODULE__),
    do: GenServer.call(pid, {:find_by_is, uuid})

  @doc """
  Receives a list of users and creates a Map where keys are the users, and the values will store the authentication tokens.
  If what receives is not a list, we want it to return {:stop, "Invalid list of users"}, exiting the process and not letting the application to start.
  """
  @impl true
  def init(users) when is_list(users) and length(users) > 0 do
    IO.inspect(users, label: "init_____")

    # state = Enum.reduce(users, %{}, &Map.put(&2, &1, nil))
    # state = Enum.reduce(users, [], &[%{"#{&1}" => nil, id: nil} | &2])
    state = Enum.reduce(users, [], &[{&1, nil, Ecto.UUID.generate()} | &2])
    IO.inspect(state, label: "state___")
    {:ok, state}
  end

  def init(_users), do: {:ok, []}

  # Initial test
  # def init(_), do: {:stop, "Invalid list of users"}

  @impl true

  def handle_call({:all}, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:new, email, context}, _from, state) do
    {:ok, token} = UserToken.generate(context, email)
    state = [{email, token, Ecto.UUID.generate()} | state]
    # state = Map.put(state, email, token)
    {:reply, state, state}
  end

  def handle_call({:exists, email}, _from, state) do
    user? = Enum.any?(state, &(elem(&1, 0) == email))
    {:reply, user?, state}
    # {:reply, Map.has_key?(state, email), state} <----
  end

  def handle_call({:save, email, session_token, uuid}, _from, state) do
    state = List.keyreplace(state, email, 0, {email, session_token, uuid})
    {:reply, {email, session_token, uuid}, state}
  end

  def handle_call({:find_by_email, email}, _from, state) do
    user = Enum.find(state, &(elem(&1, 0) == email))
    # user = Map.fetch(state, email) <----
    {:reply, user, state}
  end

  def handle_call({:find_by_token, token}, _from, state) do
    {:reply, Enum.find(state, &(elem(&1, 1) == token)), state}
  end

  def handle_call({:find_by_id, uuid}, _from, state) do
    {:reply, Enum.find(state, &(elem(&1, 2) == uuid)), state}
  end
end
