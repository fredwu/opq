defmodule OPQ.Queue do
  @moduledoc """
  A simple proxy to Erlang's queue module.
  """

  alias OPQ.Queue.DB

  @doc """
  ## Examples

      iex> Queue.init
      iex> Agent.get(OPQ.Queue.DB, & &1)
      {[], []}
  """
  def init do
    Agent.start_link(fn -> :queue.new end, name: DB)
  end

  @doc """
  ## Examples

      iex> Queue.init
      iex> Queue.get_queue
      {[], []}
  """
  def get_queue do
    Agent.get(DB, & &1)
  end

  @doc """
  ## Examples

      iex> Queue.init
      iex> Queue.enqueue("hello")
      iex> new_queue = :queue.new
      iex> new_queue = :queue.in("world", new_queue)
      iex> Queue.update_queue(new_queue)
      iex> Queue.get_queue
      {["world"], []}
  """
  def update_queue(new_queue) do
    Agent.update(DB, fn(_) -> new_queue end)
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
      iex> Queue.split(1)
      {{[], []}, {[], []}}

      iex> Queue.init
      iex> Queue.enqueue("hello")
      iex> Queue.enqueue("world")
      iex> Queue.enqueue("yes")
      iex> Queue.split(2)
      {{["world"], ["hello"]}, {["yes"], []}}

      iex> Queue.init
      iex> Queue.enqueue("hello")
      iex> Queue.enqueue("world")
      iex> Queue.enqueue("yes")
      iex> Queue.split(4)
      {{["yes", "world"], ["hello"]}, {[], []}}
  """
  def split(n) do
    try do
      :queue.split(n, get_queue())
    rescue
      ArgumentError -> :queue.split(length(), get_queue())
    end
  end

  @doc """
  ## Examples

      iex> Queue.init
      iex> Queue.to_list
      []

      iex> Queue.init
      iex> Queue.enqueue("hello")
      iex> Queue.enqueue("world")
      iex> Queue.to_list
      ["hello", "world"]
  """
  def to_list do
    :queue.to_list(get_queue())
  end

  @doc """
  ## Examples

      iex> Queue.init
      iex> Queue.length
      0

      iex> Queue.init
      iex> Queue.enqueue("hello")
      iex> Queue.enqueue("world")
      iex> Queue.length
      2
  """
  def length do
    :queue.len(get_queue())
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
end
