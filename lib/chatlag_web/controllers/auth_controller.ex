defmodule ChatlagWeb.AuthController do
  use ChatlagWeb, :controller

  alias Chatlag.Accounts
  alias Chatlag.Accounts.User

  plug :put_layout, "chat.html" when action in [:login, :create]

  def login(conn, _params) do
    IO.inspect(conn);
    ip = to_string(:inet_parse.ntoa(conn.remote_ip))

    changeset = Accounts.change_user(%User{})
    render(conn, "login.html", changeset: changeset, ip: ip)
  end

  def create(conn, %{"user" => user_params}) do

    case Accounts.create_user(user_params) do
      {:ok, user} ->
        old_path = get_session(conn, :old_path) || Routes.chat_path(conn, :index)

        conn
        |> assign(:current_user, user)
        |> put_session(:user_id, user.id)
        |> configure_session(renew: true)
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: old_path)

      {:error, %Ecto.Changeset{} = changeset} ->
        ip = to_string(:inet_parse.ntoa(conn.remote_ip))
        render(conn, "login.html", changeset: changeset, ip: ip)
    end
  end

  def logout(conn, _) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: "/")
  end
end
