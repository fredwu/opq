defmodule OPQ.WorkerSupervisor do
  @moduledoc """
  A supervisor that subscribes to `Feeder` and spins up the worker pool.
  """

  use ConsumerSupervisor

  def start_link(opts) do
    ConsumerSupervisor.start_link(__MODULE__, opts)
  end

  def init(opts) do
    children = [
      worker(opts[:worker], [], restart: :temporary)
    ]

    {
      :ok,
      children,
      strategy: :one_for_one,
      subscribe_to: [
        {opts[:name], min_demand: 0, max_demand: opts[:workers]}
      ]
    }
  end
end
