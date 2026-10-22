# OPQ: One Pooled Queue

[![Build Status](https://github.com/fredwu/opq/actions/workflows/ci.yml/badge.svg)](https://github.com/fredwu/opq/actions)
[![CodeBeat](https://codebeat.co/badges/76916047-5b66-466d-91d3-7131a269899a)](https://codebeat.co/projects/github-com-fredwu-opq-master)
[![Coverage](https://img.shields.io/coveralls/fredwu/opq.svg)](https://coveralls.io/github/fredwu/opq?branch=master)
[![Hex Version](https://img.shields.io/hexpm/v/opq.svg)](https://hex.pm/packages/opq)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/opq/)
[![Total Download](https://img.shields.io/hexpm/dt/opq.svg)](https://hex.pm/packages/opq)
[![License](https://img.shields.io/hexpm/l/opq.svg)](https://github.com/fredwu/opq/blob/master/LICENSE.md)
[![Last Updated](https://img.shields.io/github/last-commit/fredwu/opq.svg)](https://github.com/fredwu/opq/commits/master)

## Elixir Queue!

A simple, in-memory queue with worker pooling and rate limiting in Elixir. OPQ leverages Erlang's [queue](http://erlang.org/doc/man/queue.html) module and Elixir's [GenStage](https://github.com/elixir-lang/gen_stage).

Originally built to support [Crawler](https://github.com/fredwu/crawler).

## Features

- A fast, in-memory FIFO queue.
- Worker pool.
- Rate limit.
- Timeouts.
- Pause / resume / stop the queue.

See [Hex documentation](https://hexdocs.pm/opq/).

## Installation

```Elixir
def deps do
  [{:opq, "~> 4.0"}]
end
```

## Usage

### A simple example:

```elixir
{:ok, opq} = OPQ.init()

OPQ.enqueue(opq, fn -> IO.inspect("hello") end)
OPQ.enqueue(opq, fn -> IO.inspect("world") end)
```

### Specify module, function and arguments:

```elixir
{:ok, opq} = OPQ.init()

OPQ.enqueue(opq, IO, :inspect, ["hello"])
OPQ.enqueue(opq, IO, :inspect, ["world"])
```

### Specify a custom name for the queue:

```elixir
OPQ.init(name: :items)

OPQ.enqueue(:items, fn -> IO.inspect("hello") end)
OPQ.enqueue(:items, fn -> IO.inspect("world") end)
```

The returned feeder PID and its registered name address the same queue. Both
handles work with `info/1`, `queue/1`, `pause/1`, `resume/1`, and `stop/1`.
Queue options are registered by feeder PID without creating atoms per queue.
The OPQ application starts the shared Registry. If that Registry fails, its
registered feeders stop; their options do not survive as stale entries.
Registry partition failures recover under supervision. If the Registry supervisor
itself is killed, its children can still be shutting down when restart is
attempted; the OPQ application can then stop at its restart limit. Restart the
OPQ application before starting fresh queues in that case.

### Start as part of a supervision tree:

Note, when starting as part of a supervision tree, the `:name` option must be provided.

```elixir
children = [
  {OPQ, name: :items}
]
```

### Specify a custom worker to process items in the queue:

```elixir
defmodule CustomWorker do
  def start_link(item) do
    Task.start_link(fn ->
      Agent.update(:bucket, &[item | &1])
    end)
  end
end

Agent.start_link(fn -> [] end, name: :bucket)

{:ok, opq} = OPQ.init(worker: CustomWorker)

OPQ.enqueue(opq, "hello")
OPQ.enqueue(opq, "world")

Agent.get(:bucket, & &1) # => ["world", "hello"]
```

### Rate limit:

```elixir
{:ok, opq} = OPQ.init(workers: 1, interval: 1000)

Task.async(fn ->
  OPQ.enqueue(opq, fn -> IO.inspect("hello") end)
  OPQ.enqueue(opq, fn -> IO.inspect("world") end)
end)
```

If no interval is supplied, the ratelimiter will be bypassed.

### Check the queue and number of available workers:

```elixir
{:ok, opq} = OPQ.init()

OPQ.enqueue(opq, fn -> Process.sleep(1000) end)

{status, queue, available_workers} = OPQ.info(opq) # => {:normal, #OPQ.Queue<[]>, 9}

Process.sleep(1200)

{status, queue, available_workers} = OPQ.info(opq) # => {:normal, #OPQ.Queue<[]>, 10}
```

If you just need to get the queue itself:

```elixir
OPQ.queue(opq) # => #OPQ.Queue<[]>
```

### Queue

OPQ implements `Enumerable`, so you can perform enumerable functions on the queue:

```elixir
{:ok, opq} = OPQ.init()

queue = OPQ.queue(opq)

Enum.count(queue) # => 0
Enum.empty?(queue) # => true
```

### Stop the queue:

```elixir
{:ok, opq} = OPQ.init()

OPQ.enqueue(opq, fn -> IO.inspect("hello") end)
OPQ.stop(opq)
OPQ.info(opq) # => (EXIT) no process...
```

`stop/1` waits for the feeder to stop and does not change the caller's exit
trapping. Queue options are removed when the feeder exits, including an
unexpected exit. Calls to `info/1`, `queue/1`, or `stop/1` for a stopped queue
exit with `:noproc`. Enqueue, pause, and resume remain asynchronous casts.

### Pause and resume the queue:

```elixir
{:ok, opq} = OPQ.init()

OPQ.enqueue(opq, fn -> IO.inspect("hello") end) # => "hello"
OPQ.pause(opq)
OPQ.info(opq) # => {:paused, {[], []}, 10}
OPQ.enqueue(opq, fn -> IO.inspect("world") end)
OPQ.resume(opq) # => "world"
OPQ.info(opq) # => {:normal, {[], []}, 10}
```

## Configurations

| Option       | Type        | Default Value  | Description |
|--------------|-------------|----------------|-------------|
| `:name`      | atom/module | pid            | The name of the queue.
| `:worker`    | module      | `OPQ.Worker`   | The worker that processes each item from the queue.
| `:workers`   | integer     | `10`           | Maximum number of workers.
| `:interval`  | integer     | `0`            | Rate limit control - number of milliseconds before asking for more items to process, defaults to `0` which is effectively no rate limit.
| `:timeout`   | integer     | `5000`         | Number of milliseconds allowed to perform the work, it should always be set to higher than `:interval`.

## Changelog

Please see [CHANGELOG.md](CHANGELOG.md).

## License

Licensed under [MIT](http://fredwu.mit-license.org/).
