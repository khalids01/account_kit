defmodule AccountkitWeb.Sections.Headers do
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: AccountkitWeb.Endpoint,
    router: AccountkitWeb.Router,
    statics: AccountkitWeb.static_paths()

  import AccountkitWeb.Components.Navbar, only: [navbar: 1]
  import AccountkitWeb.Components.UIComponents, only: [theme_toggle: 1, user_menu: 1]

  attr :current_scope, :any, default: nil
  def home_header(assigns) do
    ~H"""
    <header>
      <.navbar
       id="home-header"
       variant="shadow"
       class="hidden md:flex"
      >
       <:start_content>
         <.link navigate={~p"/"} class="text-xl font-semibold tracking-tight"> AccountKit </.link>
       </:start_content>

       <:end_content>
          <.theme_toggle/>
          <.user_menu current_scope={@current_scope}/>
       </:end_content>
      </.navbar>
    </header>
    """
  end
end
