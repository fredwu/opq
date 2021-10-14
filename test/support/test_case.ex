defmodule OPQ.TestCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import OPQ.TestHelpers
    end
  end
end
