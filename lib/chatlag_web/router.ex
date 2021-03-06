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

  if Mix.env() == :dev do
    forward "/sent_emails", Bamboo.SentEmailViewerPlug
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

    get "/", LobbyController, :index
    get "/lobby", LobbyController, :index
    get "/policy", LobbyController, :policy
    get "/chat", LobbyController, :index
    get "/login", AuthController, :login
    get "/details", AuthController, :details
    get "/logout", AuthController, :logout
    post "/login", AuthController, :create
    put "/login", AuthController, :update
    post "/img_uploads", ChatController, :upload
  end

  scope "/", ChatlagWeb do
    pipe_through [:browser, :protected]

    get "/chat/:id", ChatController, :chat
    get "/room/create/:u1/:u2", ChatController, :create_room
  end

  scope "/auth", ChatlagWeb do
    pipe_through :browser

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end

  scope "/admin", ChatlagWeb do
    pipe_through [:browser, :admin]

    get "/", RoomController, :index
    get "/users/:id/suspend", UserController, :suspend
    get "/users/:id/unsuspend", UserController, :unsuspend
    get "/rooms/:id/del_messages", RoomController, :del_messages
    get "/rooms/:id/messages", RoomController, :messages
    resources "/rooms", RoomController
    resources "/words", WordController
    resources "/contacts", ContactController
    resources "/users", UserController
    get "/reset", RoomController, :ask_reset
    post "/reset", RoomController, :reset
  end

  # Other scopes may use custom stacks.
  # scope "/api", ChatlagWeb do
  #   pipe_through :api
  # end
end
