defmodule OPQ.Options do
  @moduledoc """
  Options for configuring OPQ.
  """

  alias OPQ.Queue.DB

  @name    DB
  @workers 10

  @doc """
  ## Examples

      iex> Options.assign_defaults([]) |> Keyword.get(:workers)
      10

      iex> Options.assign_defaults([workers: 4]) |> Keyword.get(:workers)
      4
  """
  def assign_defaults(opts) do
    Keyword.merge([
      name:    name(),
      workers: workers(),
    ], opts)
  end

  defp name,    do: Application.get_env(:opq, :name)    || @name
  defp workers, do: Application.get_env(:opq, :workers) || @workers
end
