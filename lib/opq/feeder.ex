defmodule OPQ.Feeder do
  @moduledoc """
  A GenStage producer that feeds items in a buffered queue to the consumers.
  """

  use GenStage

  def start_link(nil),  do: GenStage.start_link(__MODULE__, :ok)
  def start_link(name), do: GenStage.start_link(__MODULE__, :ok, name: name)

  def init(:ok) do
    {:producer, {:queue.new, 0}}
  end

  def handle_call(:info, _from, state) do
    {:reply, state, [], state}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :shutdown, {:shutdown, state}, state}
  end

  def handle_call({:enqueue, event}, from, {queue, pending_demand}) do
    queue = :queue.in({from, event}, queue)
    dispatch_events(queue, pending_demand, [])
  end

  def handle_demand(demand, {queue, pending_demand}) do
    dispatch_events(queue, demand + pending_demand, [])
  end

  defp dispatch_events(queue, 0, events) do
    {:noreply, Enum.reverse(events), {queue, 0}}
  end

  defp dispatch_events(queue, demand, events) do
    case :queue.out(queue) do
      {{:value, {from, event}}, queue} ->
        GenStage.reply(from, :ok)
        dispatch_events(queue, demand - 1, [event | events])
      {:empty, queue} ->
        {:noreply, Enum.reverse(events), {queue, demand}}
    end
  end
end
