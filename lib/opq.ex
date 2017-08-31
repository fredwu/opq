defmodule OPQ do
  @moduledoc """
  A simple, in-memory queue with worker pooling and rate limiting in Elixir.
  """

  alias OPQ.{Options, Feeder, RateLimiter, WorkerSupervisor}
  alias OPQ.OptionsHandler, as: Opt

  def init(opts \\ []) do
    opts
    |> Options.assign_defaults
    |> start_links
  end

  def enqueue(feeder, event) do
    GenStage.call(feeder, {:enqueue, event}, Opt.timeout(feeder))
  end

  def stop(feeder) do
    Process.flag(:trap_exit, true)
    GenStage.call(feeder, :stop, Opt.timeout(feeder))
  end

  def pause(feeder),  do: GenStage.call(feeder, :pause, Opt.timeout(feeder))
  def resume(feeder), do: GenStage.call(feeder, :resume, Opt.timeout(feeder))
  def info(feeder),   do: GenStage.call(feeder, :info, Opt.timeout(feeder))

  defp start_links(opts) do
    {:ok, feeder}       = Feeder.start_link(opts[:name])

    Opt.save_opts(opts[:name] || feeder, opts)

    opts                = Keyword.merge(opts, [name: feeder])
    {:ok, rate_limiter} = RateLimiter.start_link(opts)
    opts                = Keyword.merge(opts, [rate_limiter: rate_limiter])
    {:ok, _}            = WorkerSupervisor.start_link(opts)

    {:ok, feeder}
  end
end
