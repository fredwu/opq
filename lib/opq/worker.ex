defmodule OPQ.Worker do
  @moduledoc """
  A worker that runs a custom function.
  """

  def start_link(event) do
    Task.start_link(fn -> process_event(event) end)
  end

  defp process_event(event) when is_function(event), do: event.()
  defp process_event(event),                         do: event
end
