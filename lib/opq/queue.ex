defmodule OPQ.Queue do
  @moduledoc """
  A `:queue` wrapper so that protocols like `Enumerable` can be implemented.
  """

  @opaque t() :: %__MODULE__{data: :queue.queue()}

  defstruct data: :queue.new()
end
