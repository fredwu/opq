defmodule OPQTest do
  use OPQ.TestCase, async: true

  doctest OPQ

  test "enqueue items" do
    {:ok, pid} = OPQ.init

    OPQ.enqueue(pid, :a)
    OPQ.enqueue(pid, :b)

    wait fn ->
      {queue, _demand} = OPQ.info(pid)

      assert :queue.len(queue) == 0
    end
  end

  test "enqueue functions" do
    Agent.start_link(fn -> [] end, name: Bucket)

    {:ok, pid} = OPQ.init

    OPQ.enqueue(pid, fn -> Agent.update(Bucket, &[:a | &1]) end)
    OPQ.enqueue(pid, fn -> Agent.update(Bucket, &[:b | &1]) end)

    wait fn ->
      {queue, _demand} = OPQ.info(pid)

      assert :queue.len(queue) == 0
      assert Kernel.length(Agent.get(Bucket, & &1)) == 2
    end
  end

  test "enqueue to a named queue" do
    OPQ.init(name: :items)

    OPQ.enqueue(:items, :a)
    OPQ.enqueue(:items, :b)

    wait fn ->
      {queue, _demand} = OPQ.info(:items)

      assert :queue.len(queue) == 0
    end
  end
end
