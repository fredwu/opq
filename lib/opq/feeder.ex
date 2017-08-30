defmodule OPQ.Feeder do
  @moduledoc """
  A GenStage producer that feeds items in a buffered queue to the consumers.
  """

  use GenStage

  def start_link(nil),  do: GenStage.start_link(__MODULE__, :ok)
  def start_link(name), do: GenStage.start_link(__MODULE__, :ok, name: name)

  def init(:ok) do
    {:producer, {:normal, :queue.new, 0}}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :shutdown, state, state}
  end

  def handle_call(:pause, _from, {_status, queue, demand}) do
    dispatch_or_pause(:paused, queue, demand)
  end

  def handle_call(:resume, from, {_status, queue, demand}) do
    GenStage.reply(from, :ok)
    dispatch_events(:normal, queue, demand, [])
  end

  def handle_call(:info, _from, state) do
    {:reply, state, [], state}
  end

  def handle_call({:enqueue, event}, from, {status, queue, pending_demand}) do
    queue = :queue.in({from, event}, queue)

    dispatch_or_pause(status, queue, pending_demand)
  end

  defp dispatch_or_pause(:normal, queue, demand) do
    dispatch_events(:normal, queue, demand, [])
  end

  defp dispatch_or_pause(:paused, queue, demand) do
    {:reply, :ok, [], {:paused, queue, demand}}
  end

  def handle_demand(demand, {status, queue, pending_demand}) do
    dispatch_events(status, queue, demand + pending_demand, [])
  end

  defp dispatch_events(:paused, queue, demand, events) do
    {:noreply, Enum.reverse(events), {:paused, queue, demand}}
  end

  defp dispatch_events(status, queue, 0, events) do
    {:noreply, Enum.reverse(events), {status, queue, 0}}
  end

  defp dispatch_events(status, queue, demand, events) do
    case :queue.out(queue) do
      {{:value, {from, event}}, queue} ->
        GenStage.reply(from, :ok)
        dispatch_events(status, queue, demand - 1, [event | events])
      {:empty, queue} ->
        {:noreply, Enum.reverse(events), {status, queue, demand}}
    end
  end
end
