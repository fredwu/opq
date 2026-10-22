defmodule OPQ.LifecycleTest do
  use OPQ.TestCase, async: false

  @moduletag capture_log: true

  test "named queues use the same options through their name and returned pid" do
    queue = start_queue(name: :lifecycle_named, workers: 1, timeout: 25)
    {pid, _children} = queue

    assert OPQ.OptionsHandler.lookup(pid) == {pid, 25}
    assert OPQ.OptionsHandler.lookup(:lifecycle_named) == {pid, 25}
    assert {:normal, %OPQ.Queue{}, _demand} = OPQ.info(pid)
    assert {:normal, %OPQ.Queue{}, _demand} = OPQ.info(:lifecycle_named)
    assert OPQ.queue(:lifecycle_named) == OPQ.queue(pid)

    stop_queue(queue, :lifecycle_named)

    for handle <- [pid, :lifecycle_named] do
      assert {:noproc, _call} = catch_exit(OPQ.info(handle))
      assert {:noproc, _call} = catch_exit(OPQ.queue(handle))
      assert {:noproc, _call} = catch_exit(OPQ.stop(handle))
    end

    replacement = start_queue(name: :lifecycle_named, workers: 1, timeout: 50)
    assert OPQ.OptionsHandler.lookup(:lifecycle_named) == {elem(replacement, 0), 50}
    assert elem(replacement, 0) != pid
    stop_queue(replacement)
  end

  test "info and queue retain the configured timeout while the feeder is suspended" do
    for opts <- [
          [name: nil, workers: 1, timeout: 10],
          [name: :lifecycle_timeout, workers: 1, timeout: 20]
        ] do
      queue = start_queue(opts)
      {pid, _children} = queue
      handles = if opts[:name], do: [pid, opts[:name]], else: [pid]
      :ok = :sys.suspend(pid)

      try do
        for handle <- handles do
          assert {:timeout, _call} = catch_exit(OPQ.info(handle))
          assert {:timeout, _call} = catch_exit(OPQ.queue(handle))
        end
      after
        :ok = :sys.resume(pid)
      end

      stop_queue(queue)
    end
  end

  test "concurrent queues keep distinct options and paused work" do
    parent = self()
    queues = Enum.map(1..8, &start_queue(workers: 1, timeout: 100 + &1))

    for {{pid, _children}, index} <- Enum.with_index(queues, 1) do
      assert OPQ.OptionsHandler.lookup(pid) == {pid, 100 + index}
      OPQ.pause(pid)
      OPQ.enqueue(pid, fn -> send(parent, {:ran, index}) end)
      assert {:paused, %OPQ.Queue{} = buffered, _demand} = OPQ.info(pid)
      assert Enum.count(buffered) == 1
    end

    refute_received {:ran, _index}

    for {pid, _children} <- queues, do: OPQ.resume(pid)
    for index <- 1..8, do: assert_receive({:ran, ^index}, 1_000)
    Enum.each(queues, &stop_queue/1)
  end

  test "feeder death removes options and queue processes without affecting another queue" do
    Process.flag(:trap_exit, true)
    survivor = start_queue(workers: 1)

    for interval <- [0, 10] do
      {pid, children} = start_queue(workers: 1, interval: interval)
      refs = monitor_children(children)
      Process.exit(pid, :kill)
      assert_children_down(refs)

      wait(fn -> assert Registry.lookup(OPQ.Registry, pid) == [] end)
      assert {:noproc, _call} = catch_exit(OPQ.info(pid))
      assert {:normal, %OPQ.Queue{}, _demand} = OPQ.info(elem(survivor, 0))
    end

    stop_queue(survivor)
  end

  test "stop removes options while an active worker completes" do
    parent = self()

    for interval <- [0, 10] do
      {pid, children} = start_queue(workers: 1, interval: interval)

      OPQ.enqueue(pid, fn ->
        send(parent, {:started, self()})

        receive do
          :finish -> send(parent, {:finished, self()})
        end
      end)

      assert_receive {:started, worker}, 1_000
      on_exit(fn -> send(worker, :finish) end)
      refs = monitor_children([worker | children])
      flags = Process.info(self(), :trap_exit)
      assert OPQ.stop(pid) == :ok
      assert Process.info(self(), :trap_exit) == flags
      wait(fn -> assert Registry.lookup(OPQ.Registry, pid) == [] end)
      send(worker, :finish)
      assert_receive {:finished, ^worker}, 1_000
      assert_children_down(refs)
    end
  end

  test "registry failure retires queues and application restart permits fresh queues" do
    Process.flag(:trap_exit, true)

    for target <- [:partition, :registry] do
      {pid, children} = start_queue(workers: 1, interval: 10)
      refs = monitor_children(children)
      [{_id, partition, :worker, _modules}] = Supervisor.which_children(OPQ.Registry)
      registry = Process.whereis(OPQ.Registry)
      Process.exit(if(target == :partition, do: partition, else: registry), :kill)
      assert_children_down(refs)

      if target == :registry do
        assert Application.stop(:opq) in [:ok, {:error, {:not_started, :opq}}]
        assert {:ok, _started} = Application.ensure_all_started(:opq)
      else
        assert Process.whereis(OPQ.Registry) == registry
      end

      wait(fn ->
        assert current_registry = Process.whereis(OPQ.Registry)
        assert Process.alive?(current_registry)

        [{_id, current_partition, :worker, _modules}] =
          Supervisor.which_children(current_registry)

        assert Process.alive?(current_partition)
        refute current_partition == partition
        assert Registry.count(OPQ.Registry) == 0
      end)

      refute Process.alive?(pid)
      replacement = start_queue(workers: 1, timeout: 75)
      assert OPQ.OptionsHandler.lookup(elem(replacement, 0)) == {elem(replacement, 0), 75}
      stop_queue(replacement)
    end
  end

  test "warmed queue creation does not grow atoms or retain processes" do
    Enum.each(1..10, fn _ -> cycle_queues() end)
    atom_count = :erlang.system_info(:atom_count)
    process_count = :erlang.system_info(:process_count)

    Enum.each(1..100, fn _ -> cycle_queues() end)

    assert :erlang.system_info(:atom_count) == atom_count
    assert :erlang.system_info(:process_count) <= process_count
    assert Registry.count(OPQ.Registry) == 0
  end

  defp cycle_queues do
    queues = Enum.map([0, 0, 10, 10], &start_queue(workers: 1, interval: &1))
    named = start_queue(name: :lifecycle_reused, workers: 1)
    Enum.each([named | queues], &stop_queue/1)
  end

  defp start_queue(opts) do
    {:links, existing} = Process.info(self(), :links)
    {:ok, pid} = OPQ.init(opts)
    {:links, current} = Process.info(self(), :links)
    {pid, current -- existing}
  end

  defp stop_queue({pid, children}, handle \\ nil) do
    refs = monitor_children(children)
    flags = Process.info(self(), :trap_exit)
    assert OPQ.stop(handle || pid) == :ok
    assert Process.info(self(), :trap_exit) == flags
    assert_children_down(refs)
    wait(fn -> assert Registry.lookup(OPQ.Registry, pid) == [] end)
  end

  defp monitor_children(children), do: Enum.map(children, &{&1, Process.monitor(&1)})

  defp assert_children_down(refs) do
    for {pid, ref} <- refs do
      assert_receive {:DOWN, ^ref, :process, ^pid, _reason}, 1_000
      refute Process.alive?(pid)
    end
  end
end
