defmodule OPQ do
  @moduledoc """
  A simple, in-memory queue with worker pooling and rate limiting in Elixir.
  """

  alias OPQ.{Options, Feeder, RateLimiter, WorkerSupervisor}
  alias OPQ.OptionsHandler, as: Opt

  def init(opts \\ []) do
    opts
    |> Options.assign_defaults()
    |> start_links()
  end

  def enqueue(feeder, event) do
    GenStage.cast(feeder, {:enqueue, event})
  end

  def enqueue(feeder, mod, fun, args)
      when is_atom(mod) and
           is_atom(fun) and
           is_list(args) do
    enqueue(feeder, {mod, fun, args})
  end

  def stop(feeder) do
    Process.flag(:trap_exit, true)
    GenStage.cast(feeder, :stop)
    Opt.stop(feeder)
  end

  def pause(feeder),  do: GenStage.cast(feeder, :pause)
  def resume(feeder), do: GenStage.cast(feeder, :resume)
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
