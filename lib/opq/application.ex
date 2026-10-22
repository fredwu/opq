defmodule OPQ.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [{Registry, keys: :unique, name: OPQ.Registry}]
    Supervisor.start_link(children, strategy: :one_for_one, name: OPQ.Supervisor)
  end
end
