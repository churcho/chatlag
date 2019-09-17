defmodule ChatlagWeb.LobbyController do
  use ChatlagWeb, :controller
  import Ecto.Query

  alias Chatlag.Repo

  alias Chatlag.Chat.Room

  plug :put_layout, "empty.html" when action in [:index]

  def index(conn, params) do
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

      IO.inspect(searchQuery, label: "params")

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
end
