defmodule OPQ.OptionsHandler do
  @moduledoc """
  Looks up options registered by each feeder for its own lifetime.
  """

  def register(opts), do: Registry.register(OPQ.Registry, self(), opts)

  def lookup(feeder) do
    pid = GenServer.whereis(feeder)

    case Registry.lookup(OPQ.Registry, pid) do
      [{^pid, opts}] -> {pid, opts[:timeout]}
      [] -> exit({:noproc, {__MODULE__, :lookup, [feeder]}})
    end
  end
end
