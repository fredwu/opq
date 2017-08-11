defmodule OPQ.Feeder do
  @moduledoc """
  A GenStage producer that feeds items in the queue to the consumers.
  """

  use GenStage

  alias OPQ.Queue

  def start_link do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:producer, :ok}
  end

  def handle_demand(demand, _queue) when demand > 0 do
    {queue, new_queue} = Queue.split(demand)

    {:noreply, :queue.to_list(queue), Queue.update_queue(new_queue)}
  end
end
