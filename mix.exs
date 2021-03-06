defmodule Chatlag.MixProject do
  use Mix.Project

  def project do
    [
      app: :chatlag,
      version: "0.1.0",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Chatlag.Application, []},
      extra_applications: [
        :logger,
        :runtime_tools,
        :scrivener_ecto,
        :scrivener_html,
        :bamboo,
        :ueberauth_facebook
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4.9"},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.1"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.11"},
      # {:phoenix_live_view, github: "phoenixframework/phoenix_live_view"},
      {:phoenix_live_view, "~> 0.1.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_bootstrap_form, "~> 0.1.0"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:arc, github: "ehayun/arc"},
      {:arc_ecto, github: "ehayun/arc_ecto"},
      # {:arc, "~> 0.11.0"},
      # {:arc_ecto, "~> 0.11.2"},
      {:slugger, "~> 0.3"},
      {:timex, "~> 3.5"},
      {:pow, "~> 1.0.13"},
      {:scrivener_ecto, "~> 2.0"},
      {:scrivener_html, "~> 1.8"},
      {:memento, "~> 0.3.1"},
      {:bamboo, "~> 1.3"},
      {:ueberauth_facebook, "~> 0.8"},
      {:poison, "~> 4.0"},
      {:httpoison, "~> 1.4"},
      {:uuid, "~> 1.1"},
      {:hackney, github: "benoitc/hackney", override: true},
      {:plug_cowboy, "~> 2.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
