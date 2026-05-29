defmodule AccountkitWeb.Components.Sections.HomeHeader do
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: AccountkitWeb.Endpoint,
    router: AccountkitWeb.Router,
    statics: AccountkitWeb.static_paths()

  import AccountkitWeb.Components.Core.Logo, only: [logo: 1]
  import AccountkitWeb.Components.Core.ThemeToggle, only: [theme_toggle: 1]
  import AccountkitWeb.Components.Core.UserMenu, only: [user_menu: 1]
  import AccountkitWeb.Components.UI.Drawer, only: [drawer: 1, show_drawer: 2]
  import AccountkitWeb.Components.UI.Icon, only: [icon: 1]

  attr(:current_scope, :any, default: nil)

  def home_header(assigns) do
    assigns =
      assign(assigns, :nav_items, [
        %{label: "Home", href: ~p"/"},
        %{label: "Features", href: "#features"}
      ])

    ~H"""
    <header>
      <div
        id="home-header"
        class="hidden items-center grid-cols-[1fr_auto_1fr] gap-6 px-6 py-3 shadow md:grid"
      >
        <.logo />

        <nav aria-label="Main navigation">
          <ul class="flex items-center gap-8">
            <li :for={item <- @nav_items}>
              <.link
                href={item.href}
                class="text-sm font-medium text-base-content/70 transition hover:text-base-content"
              >
                {item.label}
              </.link>
            </li>
          </ul>
        </nav>

        <div class="flex items-center justify-end gap-3">
          <.theme_toggle />
          <.user_menu
            :if={@current_scope && @current_scope.user}
            id="desktop-user-menu"
            current_scope={@current_scope}
          />
        </div>
      </div>

      <div class="flex items-center gap-3 px-4 py-3 shadow md:hidden">
        <.logo />
        <div class="flex-1" />
        <.theme_toggle />
        <.user_menu
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
        <.logo />
      </.drawer>
    </header>
    """
  end
end
