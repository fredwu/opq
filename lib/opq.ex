defmodule OPQ do
  @moduledoc """
  A simple, in-memory queue with pooling in Elixir.
  """

  alias OPQ.{Options, Feeder, WorkerSupervisor}

  def init(opts \\ []) do
    opts
    |> Options.assign_defaults
    |> start_links
  end

  def enqueue(feeder, event) do
    GenStage.call(feeder, {:enqueue, event})
  end

  def info(feeder) do
    GenStage.call(feeder, :info)
  end

  defp start_links(opts) do
    {:ok, feeder} = Feeder.start_link(opts[:name])
    opts          = Keyword.merge(opts, [name: feeder])
    {:ok, _}      = WorkerSupervisor.start_link(opts)

    {:ok, feeder}
  end
end
