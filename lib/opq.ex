defmodule OPQ do
  @moduledoc """
  A simple, in-memory queue with worker pooling and rate limiting in Elixir.
  """

  alias OPQ.{Options, Feeder, RateLimiter, WorkerSupervisor}

  def init(opts \\ []) do
    opts
    |> Options.assign_defaults
    |> start_links
  end

  def enqueue({feeder, opts}, event) do
    GenStage.call(feeder, {:enqueue, event}, opts[:timeout])
  end

  def info({feeder, opts}) do
    GenStage.call(feeder, :info, opts[:timeout])
  end

  defp start_links(opts) do
    {:ok, feeder}       = Feeder.start_link(opts[:name])
    opts                = Keyword.merge(opts, [name: feeder])
    {:ok, rate_limiter} = RateLimiter.start_link(opts)
    opts                = Keyword.merge(opts, [rate_limiter: rate_limiter])
    {:ok, _}            = WorkerSupervisor.start_link(opts)

    {:ok, {feeder, opts}}
  end
end
