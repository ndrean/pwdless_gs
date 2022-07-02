defmodule PwdlessGs.Repo do
  use GenServer
  alias PwdlessGs.UserToken

  # require Record

  @users_topic "sync_users"
  @sync_interval 1000

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

    GenServer.start_link(__MODULE__, users, name: __MODULE__)
  end

  # def all(),
  # do: :sys.get_state(__MODULE__)
  def all,
    do: :ets.tab2list(:users)

  def exists?(email) do
    case find_by_email(email) do
      nil -> false
      _ -> true
    end
  end

  def find_by_email(email),
    # do: Enum.find(all(), &(elem(&1, 0) == email))
    do: :ets.lookup(:users, email) |> List.first()

  def find_by_token(token),
    # do: Enum.find(all(), &(elem(&1, 1) == token))
    do: :ets.match_object(:users, {:_, token, :_}) |> List.first()

  def find_by_id(uuid),
    # do: Enum.find(all(), &(elem(&1, 2) == uuid))
    do: :ets.match_object(:users, {:_, :_, uuid}) |> List.first()

  def new(email, context) do
    {:ok, token} = UserToken.generate(context, email)
    user = {email, token, Ecto.UUID.generate()}
    :ets.insert(:users, user)
  end

  def save(email, token) do
    {^email, _, uuid} = find_by_email(email)
    :ets.insert(:users, {email, token, uuid})
    {email, token, uuid}
  end

  @doc """
  Receives a list of users and creates a Map where keys are the users, and the values will store the authentication tokens.
  If what receives is not a list, we want it to return {:stop, "Invalid list of users"}, exiting the process and not letting the application to start.
  """
  @impl true
  def init(users) when is_list(users) and length(users) > 0 do
    IO.inspect(users, label: "init_____")

    name = :ets.new(:users, [:set, :public, :named_table, keypos: 1])
    IO.inspect("DB_init: ETS table #{name} started...")
    # state = Enum.reduce(users, %{}, &Map.put(&2, &1, nil))
    # state = Enum.reduce(users, [], &[%{"#{&1}" => nil, id: nil} | &2])
    state = Enum.reduce(users, [], &[{&1, :rand.uniform(20), Ecto.UUID.generate()} | &2])
    :ets.insert(:users, state)
    IO.inspect(state, label: "state___")
    {:ok, state}
  end

  def init(_users), do: {:ok, []}

  # Initial test
  # def init(_), do: {:stop, "Invalid list of users"}

  # def handle_call({:save, email, session_token, uuid}, _from, state) do
  # state = List.keyreplace(state, email, 0, {email, session_token, uuid})
  # {:reply, {email, session_token, uuid}, state}
  # end
end
