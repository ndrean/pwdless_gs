defmodule PwdlessGs.FakeEmail do
  alias Faker.Internet

  def generate do
    Stream.repeatedly(&Internet.email/0)
    |> Enum.take(0)
  end

  def users do
    Enum.reduce(
      generate(),
      [],
      &[{&1, :rand.uniform(10_000_000), Ecto.UUID.generate(), :os.system_time()} | &2]
    )
  end
end
