defmodule OPQ.Feeder do
  @moduledoc """
  A GenStage producer that feeds items in the queue to the consumers.
  """

  use GenStage

  alias OPQ.Queue

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    {:producer, opts}
  end

  def handle_demand(demand, opts) when demand > 0 do
    {queue, new_queue} = Queue.split(demand, opts[:name])

    Queue.update_queue(new_queue, opts[:name])

    {:noreply, :queue.to_list(queue), opts}
  end
end
