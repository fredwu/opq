defmodule OPQ.RateLimiter do
  @moduledoc """
  Provides rate limit.
  """

  use GenStage

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  def init(opts) do
    {:producer_consumer, {}, subscribe_to: [{opts[:name], opts}]}
  end

  def handle_subscribe(:producer, opts, from, _state) do
    {:manual, ask_and_schedule(from, {opts[:workers], opts[:interval]})}
  end

  def handle_subscribe(:consumer, _opts, _from, state) do
    {:automatic, state}
  end

  def handle_events(events, _from, {pending, interval}) do
    {:noreply, events, {pending + length(events), interval}}
  end

  def handle_info({:ask, from}, state) do
    {:noreply, [], ask_and_schedule(from, state)}
  end

  defp ask_and_schedule(from, {pending, interval}) do
    GenStage.ask(from, pending)

    Process.send_after(self(), {:ask, from}, interval)

    {0, interval}
  end
end
