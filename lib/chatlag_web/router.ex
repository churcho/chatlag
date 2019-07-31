defmodule ChatlagWeb.Router do
  use ChatlagWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :protected do
    plug Chatlag.Auth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ChatlagWeb do
    pipe_through [:browser]

    get "/", PageController, :index
    get "/chat", ChatController, :chat
    resources "/rooms", RoomController
  end

  scope "/", ChatlagWeb do
    pipe_through [:browser, :protected]

    get "/users", UserController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", ChatlagWeb do
  #   pipe_through :api
  # end
end
