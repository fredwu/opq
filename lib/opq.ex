defmodule OPQ do
  @moduledoc """
  A simple, in-memory queue with pooling in Elixir.
  """

  alias OPQ.{Options, Queue, Feeder, WorkerSupervisor}

  def start(opts \\ []) do
    opts = Options.assign_defaults(opts)

    Queue.init(opts[:name])

    start_supervision(opts)
  end

  defp start_supervision(opts) do
    import Supervisor.Spec

    children = [
      worker(Feeder, [opts]),
      worker(WorkerSupervisor, [opts])
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end
end
