defmodule AccountkitWeb.Router do
  use AccountkitWeb, :router

  use AshAuthentication.Phoenix.Router

  import AshAuthentication.Plug.Helpers

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AccountkitWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
    plug AccountkitWeb.Plugs.RemoteIp
  end

  pipeline :api do
    plug AccountkitWeb.Plugs.Cors
    plug :accepts, ["json"]

    plug AshAuthentication.Strategy.ApiKey.Plug,
      resource: Accountkit.Accounts.User,
      # if you want to require an api key to be supplied, set `required?` to true
      required?: false

    plug :load_from_bearer
    plug :set_actor, :user
  end

  scope "/", AccountkitWeb do
    pipe_through :browser

    live "/sso/login", Pages.ApplicationSso.LoginLive, :new
    live "/sso/register", Pages.ApplicationSso.RegisterLive, :new

    ash_authentication_live_session :authenticated_routes,
      on_mount: [
        {AccountkitWeb.LiveUserAuth, :assign_client_ip},
        {AccountkitWeb.LiveUserAuth, :live_no_user}
      ] do
      live "/login", Pages.Auth.LoginLive, :new
      live "/register", Pages.Auth.RegisterLive, :new

      # in each liveview, add one of the following at the top of the module:
      #
      # If an authenticated user must be present:
      # on_mount {AccountkitWeb.LiveUserAuth, :live_user_required}
      #
      # If an authenticated user *may* be present:
      # on_mount {AccountkitWeb.LiveUserAuth, :live_user_optional}
      #
      # If an authenticated user must *not* be present:
      # on_mount {AccountkitWeb.LiveUserAuth, :live_no_user}
    end
  end

  scope "/api/json" do
    pipe_through [:api]

    forward "/docs", ScalarPlug,
      path: "/api/json/docs",
      spec_href: "/api/json/open_api",
      title: "Accountkit API"

    get "/open_api", AccountkitWeb.OpenApiController, :show

    forward "/", AccountkitWeb.AshJsonApiRouter
  end

  scope "/api", AccountkitWeb do
    pipe_through [:api]

    options "/auth/validate-client", SsoAuthController, :options
    post "/auth/validate-client", SsoAuthController, :validate_client
    get "/auth/client-info", SsoAuthController, :client_info

    options "/rest/auth/login", SsoAuthController, :options
    options "/rest/auth/register", SsoAuthController, :options
    options "/rest/auth/user", SsoAuthController, :options
    options "/rest/auth/me", SsoAuthController, :options
    options "/rest/auth/logout", SsoAuthController, :options
    post "/rest/auth/login", SsoAuthController, :login
    post "/rest/auth/register", SsoAuthController, :register
    get "/rest/auth/user", SsoAuthController, :user
    get "/rest/auth/me", SsoAuthController, :me
    post "/rest/auth/logout", SsoAuthController, :logout
  end

  scope "/", AccountkitWeb do
    pipe_through :browser

    get "/", Pages.HomeController, :home
    get "/sign-in", AuthController, :redirect_to_login
    auth_routes AuthController, Accountkit.Accounts.User, path: "/auth"
    sign_out_route AuthController

    # Remove this if you do not want to use the reset password feature
    reset_route auth_routes_prefix: "/auth",
                overrides: [
                  AccountkitWeb.AuthOverrides,
                  Elixir.AshAuthentication.Phoenix.Overrides.DaisyUI
                ]

    # Remove this if you do not use the confirmation strategy
    confirm_route Accountkit.Accounts.User, :confirm_new_user,
      auth_routes_prefix: "/auth",
      overrides: [AccountkitWeb.AuthOverrides, Elixir.AshAuthentication.Phoenix.Overrides.DaisyUI]

    # Remove this if you do not use the magic link strategy.
    magic_sign_in_route(Accountkit.Accounts.User, :magic_link,
      auth_routes_prefix: "/auth",
      overrides: [AccountkitWeb.AuthOverrides, Elixir.AshAuthentication.Phoenix.Overrides.DaisyUI]
    )
  end

  # Other scopes may use custom stacks.
  # scope "/api", AccountkitWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:accountkit, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AccountkitWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/", AccountkitWeb do
    pipe_through :browser

    ash_authentication_live_session :signed_in_routes,
      on_mount: [
        {AccountkitWeb.LiveUserAuth, :assign_client_ip},
        {AccountkitWeb.LiveUserAuth, :live_user_required}
      ] do
      live "/profile", Pages.ProfileLive, :show
      live "/onboarding/organization", Pages.Onboarding.OrganizationLive, :new
    end

    ash_authentication_live_session :dashboard_routes,
      on_mount: [
        {AccountkitWeb.LiveUserAuth, :assign_client_ip},
        {AccountkitWeb.LiveUserAuth, :dashboard_user_required}
      ] do
      live "/dashboard", Pages.DashboardLive, :show
      live "/dashboard/applications", Pages.Dashboard.ApplicationsLive, :index
      live "/dashboard/organizations", Pages.Dashboard.OrganizationsLive, :index
      live "/dashboard/users", Pages.Dashboard.UsersLive, :index
      live "/dashboard/end-users", Pages.Dashboard.EndUsersLive, :index
      live "/dashboard/api-keys", Pages.Dashboard.ApiKeysLive, :index
      live "/dashboard/settings", Pages.Dashboard.SettingsLive, :index
    end

    ash_authentication_live_session :admin_routes,
      on_mount: [
        {AccountkitWeb.LiveUserAuth, :assign_client_ip},
        {AccountkitWeb.LiveUserAuth, :dashboard_user_required}
      ] do
      live "/admin/rate-limits", Pages.Admin.RateLimitsLive, :index
    end
  end

  if Application.compile_env(:accountkit, :dev_routes) do
    import AshAdmin.Router

    scope "/admin" do
      pipe_through :browser

      ash_admin "/"
    end
  end
end
