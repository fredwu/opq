defmodule OPQ.WorkerSupervisor do
  @moduledoc """
  A supervisor that subscribes to `Feeder` and spins up the worker pool.
  """

  use ConsumerSupervisor

  alias OPQ.{Feeder, Worker}

  def start_link do
    ConsumerSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      worker(Worker, [], restart: :temporary)
    ]

    {
      :ok,
      children,
      strategy: :one_for_one,
      subscribe_to: [{Feeder, max_demand: 10}]
    }
  end
end
