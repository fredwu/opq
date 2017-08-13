# OPQ: One Pooled Queue

[![Travis](https://img.shields.io/travis/fredwu/opq.svg)](https://travis-ci.org/fredwu/opq)
[![Code Climate](https://img.shields.io/codeclimate/github/fredwu/opq.svg)](https://codeclimate.com/github/fredwu/opq)
[![CodeBeat](https://codebeat.co/badges/76916047-5b66-466d-91d3-7131a269899a)](https://codebeat.co/projects/github-com-fredwu-opq-master)
[![Coverage](https://img.shields.io/coveralls/fredwu/opq.svg)](https://coveralls.io/github/fredwu/opq?branch=master) [![Hex.pm](https://img.shields.io/hexpm/v/opq.svg)](https://hex.pm/packages/opq)

A simple, in-memory queue with worker pooling and rate limiting in Elixir. OPQ leverages Erlang's [queue](http://erlang.org/doc/man/queue.html) module and Elixir's [GenStage](https://github.com/elixir-lang/gen_stage).

Originally built to support [Crawler](https://github.com/fredwu/crawler).

## Usage

A simple example:

```elixir
{:ok, pid} = OPQ.init
OPQ.enqueue(pid, fn -> IO.inspect("hello") end)
OPQ.enqueue(pid, fn -> IO.inspect("world") end)
```

Specify a custom name for the queue:

```elixir
OPQ.init(name: :items)
OPQ.enqueue(:items, fn -> IO.inspect("hello") end)
OPQ.enqueue(:items, fn -> IO.inspect("world") end)
```

Specify a custom worker to process items in the queue:

```elixir
defmodule CustomWorker do
  def start_link(item) do
    Task.start_link fn ->
      Agent.update(:bucket, &[item | &1])
    end
  end
end

Agent.start_link(fn -> [] end, name: :bucket)

{:ok, pid} = OPQ.init(worker: CustomWorker)

OPQ.enqueue(pid, "hello")
OPQ.enqueue(pid, "world")

Agent.get(:bucket, & &1) # => ["world", "hello"]
```

Check the queue and number of available workers:

```elixir
{:ok, pid} = OPQ.init
OPQ.enqueue(pid, fn -> Process.sleep(3000) end)

{queue, available_workers} = OPQ.info(pid) # => {{[], []}, 9}

# after 3 seconds...

{queue, available_workers} = OPQ.info(pid) # => {{[], []}, 10}
```

## Configurations

| Option       | Type        | Default Value  | Description |
|--------------|-------------|----------------|-------------|
| `:name`      | atom/module | pid            | The name of the queue.
| `:worker`    | module      | `OPQ.Worker`   | The worker that processes each item from the queue.
| `:workers`   | integer     | `10`           | Maximum number of workers.

## Features Backlog

- [x] A simple FIFO queue.
- [x] Worker pool via demand control.
- [ ] Rate limit.

## License

Licensed under [MIT](http://fredwu.mit-license.org/).
