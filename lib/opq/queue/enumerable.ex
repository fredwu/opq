defimpl Enumerable, for: OPQ.Queue do
  @moduledoc """
  Implementation based on https://github.com/princemaple/elixir-queue
  """

  def count(%OPQ.Queue{data: q}), do: {:ok, :queue.len(q)}

  def member?(%OPQ.Queue{data: q}, item) do
    {:ok, :queue.member(item, q)}
  end

  def reduce(%OPQ.Queue{data: q}, acc, fun) do
    Enumerable.List.reduce(:queue.to_list(q), acc, fun)
  end

  def slice(%OPQ.Queue{}), do: {:error, __MODULE__}
end
