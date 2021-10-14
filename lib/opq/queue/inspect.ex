defimpl Inspect, for: OPQ.Queue do
  @moduledoc """
  Implementation based on https://github.com/princemaple/elixir-queue
  """

  import Inspect.Algebra

  def inspect(%OPQ.Queue{} = q, opts) do
    concat(["#OPQ.Queue<", to_doc(Enum.to_list(q), opts), ">"])
  end
end
