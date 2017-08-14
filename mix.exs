defmodule OPQ.Mixfile do
  use Mix.Project

  def project do
    [
      app:               :opq,
      version:           "1.0.0",
      elixir:            "~> 1.5",
      package:           package(),
      name:              "OPQ: One Pooled Queue",
      description:       "A simple, in-memory queue with worker pooling and rate limiting in Elixir.",
      start_permanent:   Mix.env == :prod,
      deps:              deps(),
      test_coverage:     [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test],
      aliases:           ["publish": ["hex.publish", &git_tag/1]],
    ]
  end

  def application do
    [
      extra_applications: [:logger],
    ]
  end

  defp deps do
    [
      {:gen_stage,   "~> 0.12"},
      {:ex_doc,      ">= 0.0.0", only: :dev},
      {:excoveralls, "~> 0.7",   only: :test},
    ]
  end

  defp package do
    [
      maintainers: ["Fred Wu"],
      licenses:    ["MIT"],
      links:       %{"GitHub" => "https://github.com/fredwu/opq"}
    ]
  end

  defp git_tag(_args) do
    System.cmd "git", ["tag", "v" <> Mix.Project.config[:version]]
    System.cmd "git", ["push"]
    System.cmd "git", ["push", "--tags"]
  end
end
