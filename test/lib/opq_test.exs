defmodule OPQTest do
  use OPQ.TestCase, async: true

  alias OPQ.Queue

  doctest OPQ

  test "enqueue items" do
    Queue.init(:items)
    Queue.enqueue(:a, :items)
    Queue.enqueue(:b, :items)

    wait fn ->
      OPQ.start(name: :items)

      assert Queue.length(:items) == 0
    end
  end

  test "enqueue functions" do
    Agent.start_link(fn -> [] end, name: Bucket)

    Queue.init(:functions)
    Queue.enqueue(fn -> Agent.update(Bucket, &[:a | &1]) end, :functions)
    Queue.enqueue(fn -> Agent.update(Bucket, &[:b | &1]) end, :functions)

    wait fn ->
      OPQ.start(name: :functions)

      assert Queue.length(:functions) == 0
      assert Kernel.length(Agent.get(Bucket, & &1)) == 2
    end
  end
end
