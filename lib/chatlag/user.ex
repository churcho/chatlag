defmodule Chatlag.Users do
  @moduledoc """
  The Users context.
  """

  import Ecto.Query, warn: false

  alias Chatlag.Repo
  alias Chatlag.Users.User
  alias Chatlag.Workers.Cache
  alias ChatlagWeb.Presence
  @all_users_topic "chatlag"

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id, force \\ false) do
    if force do
      get_user_from_db(id)
    else
      case Cache.get_user(id) do
        %User{} = user -> user
        _ -> get_user_from_db(id)
      end
    end
  end

  defp get_user_from_db(id) do
    user = Repo.get!(User, id)
    Cache.put_user(id, user)
    user
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Suspend user.

  ## Examples

      iex> uspent_user(user_id)
      %User{}

  """
  def suspend_user(user_id) do
    user = get_user!(user_id, true)

    if user do
      cnt = user.suspend_counter + 1
      now = Timex.now()
      update_user(user, %{suspend_counter: cnt, suspend_at: now})
    else
      user
    end
  end

  def unsuspend_user(user_id) do
    user = get_user!(user_id, true)

    if user do
      update_user(user, %{suspend_at: nil})
    else
      user
    end
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    case update_user_to_db(user, attrs) do
      {:ok, user} = resp ->
        Cache.put_user(to_string(user.id), user)
        resp

      error ->
        error
    end
  end

  def update_user_to_db(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def get_user_by_uid(uid) do
    User |> where(uid: ^uid) |> Repo.one()
  end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Cache.delete_user(user.id)
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end

  def is_online?(user_id) do
    users =
      Presence.list(@all_users_topic)
      |> Enum.map(fn {_user_id, data} ->
        data[:metas]
        |> List.first()
      end)

    Enum.find(users, fn u -> u.user_id == user_id end)
  end

  def online_users do
    Presence.list(@all_users_topic)
    |> Enum.map(fn {_user_id, data} ->
      data[:metas]
      |> List.first()
    end)
  end
end
