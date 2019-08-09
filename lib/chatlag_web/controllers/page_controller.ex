defmodule ChatlagWeb.PageController do
  use ChatlagWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
