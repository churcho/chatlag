defmodule ChatlagWeb.AuthController do
  use ChatlagWeb, :controller

  alias Chatlag.Repo
  alias Chatlag.Accounts
  alias ChatlagWeb.Presence
  alias Chatlag.Accounts.User

  import Ecto.Query, only: [from: 2]

  plug :put_layout, "chat.html" when action in [:create]
  plug :put_layout, "login.html" when action in [:login]

  def login(conn, _params) do
    # user_id = get_session(conn, :user_id)
    user_id = case Pow.Plug.current_user(conn) do
      nil ->
        get_session(conn, :user_id)
      _ ->
        Pow.Plug.current_user(conn).id
    end

    if user_id do
      user = Accounts.get_user!(user_id)
      conn = assign(conn, :current_user, user)

      conn
      |> put_session(:user_id, user.id)
      |> redirect(to: "/")
      |> halt
    else
      ip = to_string(:inet_parse.ntoa(conn.remote_ip))

      changeset = Accounts.change_user(%User{})
      render(conn, "login.html", changeset: changeset, ip: ip)
    end
  end

  def create(conn, %{"user" => user_params}) do
    case get_or_create_user(user_params) do
      {:ok, user} ->
        old_path = get_session(conn, :old_path) || Routes.chat_path(conn, :index)

        Presence.track(
          self(),
          "chatlag",
          user.nickname,
          %{
            user_id: user.id,
            nickname: user.nickname
          }
        )

        conn
        |> assign(:current_user, user)
        |> put_session(:user_id, user.id)
        |> configure_session(renew: true)
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: old_path)

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset)
        ip = to_string(:inet_parse.ntoa(conn.remote_ip))
        render(conn, "login.html", changeset: changeset, ip: ip)
    end
  end

  def logout(conn, _) do
    user_id = get_session(conn, :user_id)

    if user_id do
      # UserState.user_logout(user_id)
    end

    conn
    |> configure_session(drop: true)
    |> redirect(to: "/login")
  end

  defp get_or_create_user(user_parems) do
    %{"ip_address" => ip_address, "nickname" => nickname} = user_parems

    user =
      Repo.all(
        from(u in User,
          select: %{id: u.id},
          limit: 1,
          where: u.ip_address == ^ip_address,
          where: u.nickname == ^nickname
        )
      )

    case user do
      [] ->
        Accounts.create_user(user_parems)

      _ ->
        # עדכן פרטים
        user = Accounts.get_user!(Enum.at(user, 0).id)
        Accounts.update_user(user, user_parems)
    end
  end
end
