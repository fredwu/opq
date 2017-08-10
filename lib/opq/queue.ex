defmodule OPQ.Queue do
  @moduledoc """
  A simple proxy to Erlang's queue module.
  """

  @doc """
  ## Examples

      iex> Queue.init
      iex> Agent.get(:opq_queue, & &1)
      {[], []}
  """
  def init do
    Agent.start_link(fn -> :queue.new end, name: :opq_queue)
  end

  @doc """
  ## Examples

      iex> Queue.init
      iex> Queue.enqueue("hello")
      {["hello"], []}

      iex> Queue.init
      iex> Queue.enqueue("hello")
      iex> Queue.enqueue("world")
      {["world"], ["hello"]}
  """
  def enqueue(item) do
    queue = :queue.in(item, get_queue())

    update_queue(queue)

    queue
  end

  @doc """
  ## Examples

      iex> Queue.init
      iex> Queue.enqueue("hello")
      iex> Queue.enqueue("world")
      iex> Queue.dequeue
      {"hello", {[], ["world"]}}

      iex> Queue.init
      iex> Queue.enqueue("hello")
      iex> Queue.dequeue
      {"hello", {[], []}}

      iex> Queue.init
      iex> Queue.dequeue
      {:empty, {[], []}}
  """
  def dequeue do
    queue = :queue.out(get_queue())

    update_queue(queue)

    case queue do
      {{:value, item}, new_queue} -> {item, new_queue}
      {:empty, new_queue}         -> {:empty, new_queue}
    end
  end

  @doc """
  ## Examples

      iex> Queue.init
      iex> Queue.is_empty?
      true

      iex> Queue.init
      iex> Queue.enqueue("hello")
      iex> Queue.is_empty?
      false
  """
  def is_empty? do
    :queue.is_empty(get_queue())
  end

  defp get_queue do
    Agent.get(:opq_queue, & &1)
  end

  defp update_queue(new_queue) do
    Agent.update(:opq_queue, fn(_) -> new_queue end)
  end
end
