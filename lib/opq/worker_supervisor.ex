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
      %{id: opts[:worker], start: {opts[:worker], :start_link, []}, restart: :temporary}
    ]

    cs_opts = [
      strategy: :one_for_one,
      subscribe_to: [
        {
          opts[:producer_consumer],
          min_demand: 0, max_demand: opts[:workers], timeout: opts[:timeout]
        }
      ]
    ]

    ConsumerSupervisor.init(children, cs_opts)
  end
end
