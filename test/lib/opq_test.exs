defmodule OPQTest do
  use OPQ.TestCase

  alias OPQ.Queue

  doctest OPQ

  test "enqueue items" do
    Queue.init
    Queue.enqueue(:a)
    Queue.enqueue(:b)

    OPQ.start

    wait fn ->
      assert Queue.length == 0
    end
  end

  test "enqueue functions" do
    Agent.start_link(fn -> [] end, name: Bucket)

    Queue.init
    Queue.enqueue(fn -> Agent.update(Bucket, &[:a | &1]) end)
    Queue.enqueue(fn -> Agent.update(Bucket, &[:b | &1]) end)

    OPQ.start

    wait fn ->
      assert Queue.length == 0
      assert Kernel.length(Agent.get(Bucket, & &1)) == 2
    end
  end
end
