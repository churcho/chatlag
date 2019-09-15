defmodule Chatlag.Chat do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false
  alias Chatlag.Repo

  alias Chatlag.Chat.Room
  alias Chatlag.Chat.Message
  alias Chatlag.Workers.Cache
  alias ChatlagWeb.UploadMedia

  def subscribe(topic) do
    Phoenix.PubSub.subscribe(Chatlag.PubSub, topic)
  end

  def unsubscribe(topic) do
    Phoenix.PubSub.unsubscribe(Chatlag.PubSub, topic)
  end

  @doc """
  Returns the list of rooms.

  ## Examples

      iex> list_rooms()
      [%Room{}, ...]

  """
  def list_rooms do
    Repo.all(Room)
  end

  @doc """
  Gets a single room.

  Raises `Ecto.NoResultsError` if the Room does not exist.

  ## Examples

      iex> get_room!(123)
      %Room{}

      iex> get_room!(456)
      ** (Ecto.NoResultsError)

  """
  def get_room!(id) do
    case Cache.get_room(id) do
      %Room{} = room -> room
      _ -> get_room_from_db(id)
    end

    get_room_from_db(id)
  end

  defp get_room_from_db(id) do
    room = Repo.get!(Room, id)
    Cache.put_room(id, room)
    room
  end

  @doc """
  Gets a single room by title.

  ## Examples

      iex> get_room_by_title("lobby")
      %Room{}

      iex> get_room_by_title("lobby")
      nil
  """
  def get_room_by_title(title) do
    Room |> where(title: ^title) |> Repo.one()
  end

  @doc """
  Creates a room.

  ## Examples

      iex> create_room(%{field: value})
      {:ok, %Room{}}

      iex> create_room(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_room(attrs \\ %{}) do
    %Room{}
    |> Room.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a room.

  ## Examples

      iex> update_room(room, %{field: new_value})
      {:ok, %Room{}}

      iex> update_room(room, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_room(%Room{} = room, attrs) do
    case update_room_to_db(room, attrs) do
      {:ok, room} = resp ->
        Cache.put_room(to_string(room.id), room)
        resp

      error ->
        error
    end
  end

  def update_room_to_db(%Room{} = room, attrs) do
    room
    |> Room.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Room.

  ## Examples

      iex> delete_room(room)
      {:ok, %Room{}}

      iex> delete_room(room)
      {:error, %Ecto.Changeset{}}

  """
  def delete_room(%Room{} = room) do
    # rid = room.id
    # Repo.delete_all(
    #   from m in Message,
    #   where: m.room_id = rid
    # )
    Cache.delete_room(room.id)
    Repo.delete(room)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking room changes.

  ## Examples

      iex> change_room(room)
      %Ecto.Changeset{source: %Room{}}

  """
  def change_room(%Room{} = room) do
    Room.changeset(room, %{})
  end

  alias Chatlag.Chat.Message

  @doc """
  Returns the list of messagese.

  ## Examples

      iex> list_messagese()
      [%Message{}, ...]

  """
  def list_messagese(room_id, l \\ nil) do
    l = l || 100

    qry =
      "SELECT * FROM messagese  where id in (select id from messagese where room_id = #{room_id} order by id desc limit #{
        l
      }) order by id"

    res = Ecto.Adapters.SQL.query!(Repo, qry, [])

    cols = Enum.map(res.columns, &String.to_atom(&1))

    Enum.map(res.rows, fn row ->
      struct(Message, Enum.zip(cols, row))
    end)

    # case l do
    #   nil ->
    #     Message
    #     |> where(room_id: ^room_id)
    #     |> Repo.all()

    #   _ ->
    #     Message
    #     |> where(room_id: ^room_id)
    #     |> Repo.all()
    # end
  end

  @doc """
  Gets a single message.

  Raises `Ecto.NoResultsError` if the Message does not exist.

  ## Examples

      iex> get_message!(123)
      %Message{}

      iex> get_message!(456)
      ** (Ecto.NoResultsError)

  """
  def get_message!(id), do: Repo.get!(Message, id)

  def get_msg_by_reply(reply_to) do
    Message |> where(reply_to: ^reply_to) |> Repo.all()
  end

  @doc """
  Creates a message.

  ## Examples

      iex> create_message(%{field: value})
      {:ok, %Message{}}

      iex> create_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_message(attrs \\ %{}) do
    msg =
      %Message{}
      |> Message.changeset(attrs)
      |> Repo.insert()
      |> notify_subs([:message, :inserted])

    # IO.inspect(msg, label: "after create")

    case msg do
      {:ok, msg} ->
        case fileSaved = UploadMedia.save_media(msg) do
          _ ->
            :error

          _ ->
            IO.inspect(fileSaved, label: "File saved ")
        end

      _ ->
        :error
    end

    msg
  end

  @doc """
  Updates a message.

  ## Examples

      iex> update_message(message, %{field: new_value})
      {:ok, %Message{}}

      iex> update_message(message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_message(%Message{} = message, attrs) do
    message
    |> Message.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Message.

  ## Examples

      iex> delete_message(message)
      {:ok, %Message{}}

      iex> delete_message(message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking message changes.

  ## Examples

      iex> change_message(message)
      %Ecto.Changeset{source: %Message{}}

  """
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end

  defp notify_subs({:ok, result}, event) do
    Phoenix.PubSub.broadcast(
      Chatlag.PubSub,
      "Chatlag-msg:#{result.room_id}",
      {__MODULE__, event, result}
    )

    {:ok, result}
  end

  defp notify_subs({:error, reason}, _event) do
    {:error, reason}
  end
end
