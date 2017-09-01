defmodule OPQ.OptionsHandler do
  @moduledoc """
  Saves and loads options to pass around.
  """

  def save_opts(feeder, opts) do
    Agent.start_link(fn -> opts end, name: name(feeder))
  end

  def timeout(feeder), do: load_opts(feeder)[:timeout]

  def stop(feeder), do: Agent.stop(name(feeder))

  defp load_opts(feeder), do: Agent.get(name(feeder), & &1)
  defp name(feeder),      do: :"opq-#{Kernel.inspect(feeder)}"
end
