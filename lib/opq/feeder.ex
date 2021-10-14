defmodule OPQ.Feeder do
  @moduledoc """
  A GenStage producer that feeds items in a buffered queue to the consumers.
  """

  use GenStage

  def start_link(nil), do: GenStage.start_link(__MODULE__, :ok)
  def start_link(name), do: GenStage.start_link(__MODULE__, :ok, name: name)

  def init(:ok) do
    {:producer, {:normal, %OPQ.Queue{}, 0}}
  end

  def handle_cast(:stop, state) do
    {:stop, :shutdown, state}
  end

  def handle_cast(:pause, {_status, queue, demand}) do
    dispatch_or_pause(:paused, queue, demand)
  end

  def handle_cast(:resume, {_status, queue, demand}) do
    dispatch_events(:normal, queue, demand, [])
  end

  def handle_cast({:enqueue, event}, {status, %OPQ.Queue{data: data}, pending_demand}) do
    data = :queue.in(event, data)

    dispatch_or_pause(status, %OPQ.Queue{data: data}, pending_demand)
  end

  def handle_call(:info, _from, state) do
    {:reply, state, [], state}
  end

  def handle_call(:queue, _from, {_status, queue, _demand} = state) do
    {:reply, queue, [], state}
  end

  defp dispatch_or_pause(:normal, queue, demand) do
    dispatch_events(:normal, queue, demand, [])
  end

  defp dispatch_or_pause(:paused, queue, demand) do
    {:noreply, [], {:paused, queue, demand}}
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

  defp dispatch_events(status, %OPQ.Queue{data: data}, demand, events) do
    case :queue.out(data) do
      {{:value, event}, data} ->
        dispatch_events(status, %OPQ.Queue{data: data}, demand - 1, [event | events])

      {:empty, data} ->
        {:noreply, Enum.reverse(events), {status, %OPQ.Queue{data: data}, demand}}
    end
  end
end
