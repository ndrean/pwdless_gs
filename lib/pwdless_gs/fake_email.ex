defmodule PwdlessGs.FakeEmail do
  def generate do
    Stream.repeatedly(fn ->
      FakerElixir.Helper.unique!(:unique_emails, fn ->
        FakerElixir.Internet.email()
      end)
    end)
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
