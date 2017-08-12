defmodule OPQ.WorkerSupervisor do
  @moduledoc """
  A supervisor that subscribes to `Feeder` and spins up the worker pool.
  """

  use ConsumerSupervisor

  alias OPQ.{Feeder, Worker}

  def start_link(opts) do
    ConsumerSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    children = [
      worker(Worker, [], restart: :temporary)
    ]

    {
      :ok,
      children,
      strategy: :one_for_one,
      subscribe_to: [{Feeder, max_demand: opts[:workers]}]
    }
  end
end
