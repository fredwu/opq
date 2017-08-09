defmodule OPQ.Queue do
  @moduledoc """
  A simple proxy to Erlang's queue module.
  """

  @doc """
  ## Examples

      iex> Queue.init
      {[], []}
  """
  defdelegate init, to: :queue, as: :new

  @doc """
  ## Examples

      iex> Queue.init
      iex> |> Queue.enqueue("hello")
      {["hello"], []}

      iex> Queue.init
      iex> |> Queue.enqueue("hello")
      iex> |> Queue.enqueue("world")
      {["world"], ["hello"]}
  """
  def enqueue(queue, item), do: :queue.in(item, queue)

  @doc """
  ## Examples

      iex> Queue.init
      iex> |> Queue.enqueue("hello")
      iex> |> Queue.enqueue("world")
      iex> |> Queue.dequeue
      {"hello", {[], ["world"]}}

      iex> Queue.init
      iex> |> Queue.enqueue("hello")
      iex> |> Queue.dequeue
      {"hello", {[], []}}

      iex> Queue.init
      iex> |> Queue.dequeue
      {:empty, {[], []}}
  """
  def dequeue(queue) do
    case :queue.out(queue) do
      {{:value, item}, new_queue} -> {item, new_queue}
      {:empty, new_queue}         -> {:empty, new_queue}
    end
  end

  @doc """
  ## Examples

      iex> Queue.init
      iex> |> Queue.is_empty?
      true

      iex> Queue.init
      iex> |> Queue.enqueue("hello")
      iex> |> Queue.is_empty?
      false
  """
  defdelegate is_empty?(queue), to: :queue, as: :is_empty
end
