defmodule ChatlagWeb.Router do
  use ChatlagWeb, :router
  use Pow.Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug PlugForwardedPeer
  end

  pipeline :admin do
    plug Pow.Plug.RequireAuthenticated,
      error_handler: Pow.Phoenix.PlugErrorHandler
  end

  pipeline :protected do
    plug Chatlag.Auth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/" do
    pipe_through :browser
    pow_routes()
  end

  scope "/", ChatlagWeb do
    pipe_through [:browser]

    get "/", ChatController, :index
    get "/lobby", LobbyController, :index
    get "/chat", ChatController, :index
    get "/login", AuthController, :login
    get "/logout", AuthController, :logout
    post "/login", AuthController, :create
  end

  scope "/", ChatlagWeb do
    pipe_through [:browser, :protected]

    get "/chat/:id", ChatController, :chat
    get "/room/create/:u1/:u2", ChatController, :create_room
  end

  scope "/admin", ChatlagWeb do
    pipe_through [:browser, :admin]

    get "/", RoomController, :index
    resources "/rooms", RoomController
    get "/users", UserController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", ChatlagWeb do
  #   pipe_through :api
  # end
end
