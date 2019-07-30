defmodule Chatlag.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :full_name, :string, null: true, size: 60
      add :nickname, :string, null: false
      add :email, :string, null: true
      add :password_hash, :string, null: true, size: 60
      add :role, :string, null: false, default: "visitor"
      add :age, :integer, null: false
      add :gender, :string, null: false, size: 2
      add :ip_address, :string, size: 20, null: true
      add :suspend_at, :date, null: true

      timestamps()
    end

  end
end
