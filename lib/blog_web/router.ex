defmodule BlogWeb.Router do
  use BlogWeb, :router

  pipeline :browser_without_session do
    plug(:accepts, ["html"])
    plug(:put_root_layout, {BlogWeb.LayoutView, :root})

    plug(:put_secure_browser_headers, %{
      "content-security-policy" =>
        "default-src 'self'; img-src 'self'; connect-src https://exlytics.corybuecker.com; style-src 'self' https://fonts.googleapis.com; font-src https://fonts.gstatic.com",
      "referrer-policy" => "no-referrer"
    })
  end

  pipeline :enforced_ssl do
    plug(Plug.SSL, rewrite_on: [:x_forwarded_host, :x_forwarded_port, :x_forwarded_proto])
  end

  scope "/", BlogWeb do
    pipe_through(:browser_without_session)

    get("/healthcheck", PageController, :index)

    pipe_through(:enforced_ssl)

    get("/", PageController, :index)
    get("/post/:slug", PageController, :show)
  end

  # Other scopes may use custom stacks.
  # scope "/api", BlogWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through(:browser_without_session)
      live_dashboard("/dashboard", metrics: BlogWeb.Telemetry)
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  # if Mix.env() == :dev do
  #   scope "/dev" do
  #     pipe_through(:browser_with_session)

  #     forward("/mailbox", Plug.Swoosh.MailboxPreview)
  #   end
  # end
end
