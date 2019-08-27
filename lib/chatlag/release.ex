defmodule Chatlag.Release do
  @app :chatlag

  alias Chatlag.RoomStatus

  def migrate do
    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(version) do
    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
    end
  end

  defp repos do
    Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end

  def credb do
    nodes = [node()]

    # Create the schema
    Memento.stop()
    Memento.Schema.create(nodes)
    Memento.start()

    # Memento.Table.create!(RoomStatus, disc_copies: nodes)
    Memento.Table.create!(RoomStatus)
  end
end
