defmodule ChatlagWeb.RoomController do
  use ChatlagWeb, :controller

  alias Chatlag.Chat
  alias Chatlag.Chat.Room

  def index(conn, _params) do
    rooms = Chat.list_rooms()
    render(conn, layout: {ChatlagWeb.LayoutView, "admin.html"}, rooms: rooms)
  end

  def new(conn, _params) do
    changeset = Chat.change_room(%Room{})

    render(conn, layout: {ChatlagWeb.LayoutView, "admin.html"}, changeset: changeset)
  end

  def create(conn, %{"room" => room_params}) do
    case Chat.create_room(room_params) do
      {:ok, _room} ->
        conn
        |> put_flash(:info, "Room created successfully.")
        |> redirect(to: Routes.room_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, layout: {ChatlagWeb.LayoutView, "admin.html"}, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    room = Chat.get_room!(id)
    render(conn, layout: {ChatlagWeb.LayoutView, "admin.html"}, room: room)
  end

  def edit(conn, %{"id" => id}) do
    room = Chat.get_room!(id)
    changeset = Chat.change_room(room)
    render(conn, layout: {ChatlagWeb.LayoutView, "admin.html"}, room: room, changeset: changeset)
  end

  def update(conn, %{"id" => id, "room" => room_params}) do
    room = Chat.get_room!(id)

    case Chat.update_room(room, room_params) do
      {:ok, _room} ->
        conn
        |> put_flash(:info, "Room updated successfully.")
        |> redirect(to: Routes.room_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, layout: {ChatlagWeb.LayoutView, "admin.html"}, room: room, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    room = Chat.get_room!(id)
    {:ok, _room} = Chat.delete_room(room)

    conn
    |> put_flash(:info, "Room deleted successfully.")
    |> redirect(to: Routes.room_path(conn, :index))
  end
end
