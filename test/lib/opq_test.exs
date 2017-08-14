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
      assert Agent.get(Bucket, & &1) == [:b, :a]
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

  test "run out of demands from the workers" do
    {:ok, pid} = OPQ.init(workers: 2)

    OPQ.enqueue(pid, :a)
    OPQ.enqueue(pid, :b)

    wait fn ->
      {queue, _demand} = OPQ.info(pid)

      assert :queue.len(queue) == 0
    end
  end

  test "single worker" do
    {:ok, pid} = OPQ.init(workers: 1)

    OPQ.enqueue(pid, :a)
    OPQ.enqueue(pid, :b)

    wait fn ->
      {queue, _demand} = OPQ.info(pid)

      assert :queue.len(queue) == 0
    end
  end

  test "custom worker" do
    defmodule CustomWorker do
      def start_link(item) do
        Task.start_link fn ->
          Agent.update(CustomWorkerBucket, &[item | &1])
        end
      end
    end

    Agent.start_link(fn -> [] end, name: CustomWorkerBucket)

    {:ok, pid} = OPQ.init(worker: CustomWorker)

    OPQ.enqueue(pid, :a)
    OPQ.enqueue(pid, :b)

    wait fn ->
      assert Agent.get(CustomWorkerBucket, & &1) == [:b, :a]
    end
  end

  test "rate limit" do
    Agent.start_link(fn -> [] end, name: RateLimitBucket)

    {:ok, pid} = OPQ.init(workers: 1, interval: 10)

    Task.async fn ->
      OPQ.enqueue(pid, fn -> Agent.update(RateLimitBucket, &[:a | &1]) end)
      OPQ.enqueue(pid, fn -> Agent.update(RateLimitBucket, &[:b | &1]) end)
    end

    Process.sleep(5)

    assert Agent.get(RateLimitBucket, & &1) == [:a]

    wait fn ->
      assert Agent.get(RateLimitBucket, & &1) == [:b, :a]
    end
  end
end
