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
  def enqueue({feeder, opts}, mod, func, args)
    when is_atom(mod)
    when is_atom(func)
    when is_list(args) do
    enqueue({feeder, opts}, {mod, func, args})
  end

  def stop({feeder, opts}) do
    Process.flag(:trap_exit, true)
    GenStage.call(feeder, :stop, opts[:timeout])
  end

  def pause({feeder, opts}),  do: GenStage.call(feeder, :pause, opts[:timeout])
  def resume({feeder, opts}), do: GenStage.call(feeder, :resume, opts[:timeout])
  def info({feeder, opts}),   do: GenStage.call(feeder, :info, opts[:timeout])

  defp start_links(opts) do
    {:ok, feeder}       = Feeder.start_link(opts[:name])
    opts                = Keyword.merge(opts, [name: feeder])
    {:ok, rate_limiter} = RateLimiter.start_link(opts)
    opts                = Keyword.merge(opts, [rate_limiter: rate_limiter])
    {:ok, _}            = WorkerSupervisor.start_link(opts)

    {:ok, {feeder, opts}}
  end
end
