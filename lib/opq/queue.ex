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
  def init(name \\ DB) do
    Agent.start_link(fn -> :queue.new end, name: name)
  end

  @doc """
  ## Examples

      iex> Queue.init
      iex> Queue.get_queue
      {[], []}
  """
  def get_queue(name \\ DB) do
    Agent.get(name, & &1)
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
  def update_queue(new_queue, name \\ DB) do
    Agent.update(name, fn(_) -> new_queue end)
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
  def enqueue(item, name \\ DB) do
    queue = :queue.in(item, get_queue(name))

    update_queue(queue, name)

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
  def dequeue(name \\ DB) do
    queue = :queue.out(get_queue(name))

    update_queue(queue, name)

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
  def split(n, name \\ DB) do
    try do
      :queue.split(n, get_queue(name))
    rescue
      ArgumentError -> :queue.split(__MODULE__.length(name), get_queue(name))
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
  def to_list(name \\ DB) do
    :queue.to_list(get_queue(name))
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
  def length(name \\ DB) do
    :queue.len(get_queue(name))
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
  def is_empty?(name \\ DB) do
    :queue.is_empty(get_queue(name))
  end
end
