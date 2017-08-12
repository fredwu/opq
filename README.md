# OPQ: One Pooled Queue

[![Travis](https://img.shields.io/travis/fredwu/opq.svg)](https://travis-ci.org/fredwu/opq)
[![Code Climate](https://img.shields.io/codeclimate/github/fredwu/opq.svg)](https://codeclimate.com/github/fredwu/opq)
[![CodeBeat](https://codebeat.co/badges/76916047-5b66-466d-91d3-7131a269899a)](https://codebeat.co/projects/github-com-fredwu-opq-master)
[![Coverage](https://img.shields.io/coveralls/fredwu/opq.svg)](https://coveralls.io/github/fredwu/opq?branch=master)

A simple, in-memory queue with pooling in Elixir.

Originally built to support [Crawler](https://github.com/fredwu/crawler).

## Usage

```elixir
OPQ.start(workers: 10)
```

## Configurations

| Option       | Type    | Default Value | Description |
|--------------|---------|---------------|-------------|
| `:workers`   | integer | 10            | Maximum number of workers.

## Features Backlog

- [x] A simple FIFO queue.
- [x] Worker pool via demand control.
- [ ] Wait timeout on the queue so the program exits itself accordingly.
- [ ] Rate limit.

## License

Licensed under [MIT](http://fredwu.mit-license.org/).
