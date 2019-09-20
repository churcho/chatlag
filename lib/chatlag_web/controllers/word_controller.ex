defmodule ChatlagWeb.WordController do
  use ChatlagWeb, :controller

  alias Chatlag.Reserved
  alias Chatlag.Reserved.Word

  # when action in [:index]
  plug :put_layout, "admin.html"

  def index(conn, _params) do
    words = Reserved.list_words()

    counts =
      case words do
        nil -> 0
        _ -> Enum.count(words)
      end

    render(conn, layout: {ChatlagWeb.LayoutView, "admin.html"}, words: words, counts: counts)
  end

  def new(conn, _params) do
    changeset = Reserved.change_word(%Word{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"word" => word_params}) do
    case Reserved.create_word(word_params) do
      {:ok, word} ->
        conn
        |> put_flash(:info, "Word created successfully.")
        |> redirect(to: Routes.word_path(conn, :show, word))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    word = Reserved.get_word!(id)
    render(conn, "show.html", word: word)
  end

  def edit(conn, %{"id" => id}) do
    word = Reserved.get_word!(id)
    changeset = Reserved.change_word(word)
    render(conn, "edit.html", word: word, changeset: changeset)
  end

  def update(conn, %{"id" => id, "word" => word_params}) do
    word = Reserved.get_word!(id)

    case Reserved.update_word(word, word_params) do
      {:ok, word} ->
        conn
        |> put_flash(:info, "Word updated successfully.")
        |> redirect(to: Routes.word_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", word: word, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    word = Reserved.get_word!(id)
    {:ok, _word} = Reserved.delete_word(word)

    conn
    |> put_flash(:info, "Word deleted successfully.")
    |> redirect(to: Routes.word_path(conn, :index))
  end
end
