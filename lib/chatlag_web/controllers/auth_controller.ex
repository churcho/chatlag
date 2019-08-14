defmodule ChatlagWeb.AuthController do
  use ChatlagWeb, :controller

  alias Chatlag.Accounts
  alias Chatlag.Accounts.User

  plug :put_layout, "chat.html" when action in [:login, :create]

  def login(conn, _params) do
    changeset = Accounts.change_user(%User{})
    render(conn, "login.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        ####### --- TODO

        old_path = get_session(conn, :old_path) || Routes.chat_path(conn, :index) 

        conn
        |> assign(:current_user, user)
        |> put_session(:user_id, user.id)
        |> configure_session(renew: true)
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: old_path)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "login.html", changeset: changeset)
    end
  end
end
