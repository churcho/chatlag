defmodule ChatlagWeb.LobbyController do
  use ChatlagWeb, :controller
  import Ecto.Query

  alias Chatlag.Repo

  alias Chatlag.Chat.Room

  plug :put_layout, "empty.html" when action in [:index]

  def policy(conn, _params) do
    render(conn, "policy.html")
  end

  def oldindex(conn, params) do
    search = params["search"]

    if search do
      search_term = "%#{params["search"]}%"

      searchQuery =
        Repo.all(
          from r in Room,
            select: %{id: r.id},
            where:
              like(r.title, ^search_term) or
                like(r.slogen, ^search_term) or
                like(r.small_desc, ^search_term)
        )

      case searchQuery do
        [] ->
          IO.puts("Nothing found")

        nil ->
          IO.puts("Nothing found")

        _ ->
          room = searchQuery |> Enum.at(0)

          conn
          |> redirect(to: "/chat/#{room.id}")
          |> halt
      end
    end

    user_id = get_session(conn, :user_id)

    current_user = Pow.Plug.current_user(conn)

    Phoenix.LiveView.Controller.live_render(
      conn,
      ChatlagWeb.Live.Frontpage,
      session: %{user_id: user_id, current_user: current_user}
    )
  end

  def index(conn, _params) do
    room = Repo.one(from x in Room, order_by: [asc: x.id], limit: 1)

    conn
    |> redirect(to: "/chat/#{room.id}")
    |> halt
  end
end
