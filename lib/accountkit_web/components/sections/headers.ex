defmodule AccountkitWeb.Sections.Headers do
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: AccountkitWeb.Endpoint,
    router: AccountkitWeb.Router,
    statics: AccountkitWeb.static_paths()

  import AccountkitWeb.Components.Navbar, only: [navbar: 1]
  import AccountkitWeb.Components.UIComponents, only: [theme_toggle: 1, user_menu: 1]
  import AccountkitWeb.Components.Drawer, only: [drawer: 1, show_drawer: 2]
  import AccountkitWeb.Components.Icon, only: [icon: 1]

  attr(:current_scope, :any, default: nil)

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

       <div class="flex items-center gap-3 px-4 py-3 shadow md:hidden">
         <.link navigate={~p"/"} class="text-xl font-semibold tracking-tight">AccountKit</.link>
         <div class="flex-1" />
         <.theme_toggle />
         <.user_menu
           :if={@current_scope && @current_scope.user}
           id="mobile-user-menu"
           current_scope={@current_scope}
         />
         <button
           type="button"
           class="inline-flex items-center justify-center rounded-lg p-2 hover:bg-base-200"
           phx-click={show_drawer("mobile-menu", "right")}
           aria-label="Open menu"
           aria-controls="mobile-menu"
         >
           <.icon name="hero-bars-3" class="size-6" />
           <span class="sr-only">Open menu</span>
         </button>
       </div>

       <.drawer id="mobile-menu" position="right">
         <:header>
           <h2 class="text-2xl font-bold">Menu</h2>
         </:header>
         <.link navigate={~p"/"} class="text-xl font-semibold tracking-tight"> AccountKit </.link>
       </.drawer>
    </header>

    """
  end
end
