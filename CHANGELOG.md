# OPQ Changelog

## master

- [Added] Graceful handling of exit signals in the default worker

## v4.0.2 [2023-06-13]

- [Improved] Updated all the dependencies

## v4.0.1 [2021-10-14]

- [Fixed] Wrong link to the project

## v4.0.0 [2021-10-14]

- [Added] `OPQ.Queue` wraps `:queue` and implements `Enumerable`

## v3.3.0 [2021-10-12]

- [Added] The ability to start as part of a supervision tree

## v3.2.0 [2021-10-11]

- [Improved] Updated to the new `ConsumerSupervisor` syntax
- [Improved] Updated all the dependencies

## v3.1.1 [2018-10-15]

- [Fixed] Infinite loop without rate limiting (thanks @Harrisonl)

## v3.1.0 [2018-07-30]

- [Improved] Varies small fixes and improvements
- [Improved] Use `cast` instead of `call` to avoid timeouts

## v3.0.1 [2017-09-02]

- [Fixed] Agent should be stopped too when `OPQ.stop/1` is called
- [Improved] Varies small fixes and improvements

## v3.0.0 [2017-08-31]

- [Added] Added support for enqueueing MFAs
- [Improved] Simplified named queue API by storing `opts`
- [Improved] Varies small fixes and improvements

## v2.0.1 [2017-08-30]

- [Improved] Event dispatching should immediately be paused
- [Improved] Varies small fixes and improvements

## v2.0.0 [2017-08-29]

- [Added] Pause / resume / stop the queue
- [Improved] Varies small fixes and improvements

## v1.0.1 [2017-08-14]

- [Improved] Varies small fixes and improvements

## v1.0.0 [2017-08-14]

- [Added] A fast, in-memory FIFO queue
- [Added] Worker pool
- [Added] Rate limit
- [Added] Timeouts
- [Improved] Varies small fixes and improvements
