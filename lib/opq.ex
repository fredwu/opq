defmodule OPQ do
  @moduledoc """
  A simple, in-memory queue with pooling in Elixir.
  """

  alias OPQ.{Queue, Feeder, WorkerSupervisor}

  def start do
    import Supervisor.Spec

    Queue.init

    children = [
      worker(Feeder, []),
      worker(WorkerSupervisor, [])
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end
end
