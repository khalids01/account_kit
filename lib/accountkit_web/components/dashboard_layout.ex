defmodule AccountkitWeb.Components.DashboardLayout do
  @moduledoc """
  Shared shell for control-plane dashboard pages.
  """
  use Phoenix.Component

  alias Accountkit.Accounts.Authorization

  use Phoenix.VerifiedRoutes,
    endpoint: AccountkitWeb.Endpoint,
    router: AccountkitWeb.Router,
    statics: AccountkitWeb.static_paths()

  import AccountkitWeb.Components.Icon, only: [icon: 1]
  import AccountkitWeb.Components.UIComponents, only: [theme_toggle: 1, user_menu: 1]

  attr :flash, :map, required: true
  attr :current_scope, :map, required: true
  attr :dashboard_context, :map, required: true
  attr :sidebar_collapsed?, :boolean, required: true
  attr :page_title, :string, required: true
  attr :active_nav, :atom, required: true

  slot :inner_block, required: true

  def dashboard_layout(assigns) do
    assigns =
      assign(assigns, :platform_owner?, Authorization.platform_owner?(assigns.current_scope.user))

    ~H"""
    <AccountkitWeb.Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen bg-base-200/50 text-base-content">
        <aside class={[
          "fixed inset-y-0 left-0 z-40 flex flex-col border-r border-base-300 bg-base-100 transition-all duration-200",
          if(@sidebar_collapsed?,
            do: "-translate-x-full md:w-20 md:translate-x-0",
            else: "w-72 translate-x-0"
          )
        ]}>
          <div class="flex h-16 items-center border-b border-base-300 px-4">
            <div class="flex size-10 shrink-0 items-center justify-center rounded-xl bg-primary text-sm font-bold text-primary-content">
              {String.first(@dashboard_context.logo)}
            </div>
            <div :if={!@sidebar_collapsed?} class="ml-3 min-w-0">
              <p class="truncate text-sm font-semibold">{@dashboard_context.logo}</p>
              <p class="truncate text-xs text-base-content/60">{@dashboard_context.label}</p>
            </div>
          </div>

          <nav class="flex-1 space-y-1 p-3">
            <.dashboard_nav_item
              icon="hero-squares-2x2"
              label="Overview"
              href={~p"/dashboard"}
              collapsed?={@sidebar_collapsed?}
              active={@active_nav == :overview}
            />

            <.dashboard_nav_item
              :if={@platform_owner?}
              icon="hero-building-office-2"
              label="Organizations"
              href={~p"/dashboard/organizations"}
              collapsed?={@sidebar_collapsed?}
              active={@active_nav == :organizations}
            />

            <.dashboard_nav_item
              icon="hero-users"
              label="Users"
              href="#"
              collapsed?={@sidebar_collapsed?}
              active={@active_nav == :users}
            />
            <.dashboard_nav_item
              icon="hero-key"
              label="API keys"
              href="#"
              collapsed?={@sidebar_collapsed?}
              active={@active_nav == :api_keys}
            />
            <.dashboard_nav_item
              icon="hero-cog-6-tooth"
              label="Settings"
              href="#"
              collapsed?={@sidebar_collapsed?}
              active={@active_nav == :settings}
            />
          </nav>
        </aside>

        <div class={[
          "min-h-screen transition-all duration-200",
          if(@sidebar_collapsed?, do: "md:pl-20", else: "md:pl-72")
        ]}>
          <header class="sticky top-0 z-30 flex h-16 items-center justify-between border-b border-base-300 bg-base-100/95 px-4 backdrop-blur">
            <div class="flex items-center gap-3">
              <button
                type="button"
                class="inline-flex size-10 items-center justify-center rounded-xl border border-base-300 hover:bg-base-200"
                phx-click="toggle_sidebar"
                aria-label="Toggle sidebar"
              >
                <.icon name="hero-bars-3" class="size-5" />
              </button>
              <div>
                <h1 class="text-lg font-semibold">{@page_title}</h1>
                <p class="text-xs text-base-content/60">{@dashboard_context.label}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <.theme_toggle />
              <.user_menu id="dashboard-user-menu" current_scope={@current_scope} />
            </div>
          </header>

          <main class="p-1.5 sm:p-2.5">
            {render_slot(@inner_block)}
          </main>
        </div>
      </div>
    </AccountkitWeb.Layouts.app>
    """
  end

  @doc false
  def dashboard_context(user) do
    cond do
      Authorization.platform_owner?(user) ->
        %{type: :platform, logo: "AccountKit", label: "Platform dashboard", kicker: "Platform"}

      membership = Authorization.first_org_membership(user) ->
        organization = membership.organization

        %{
          type: :organization,
          logo: organization.text_logo,
          label: organization.name,
          kicker: "Organization"
        }
    end
  end

  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :href, :string, required: true
  attr :collapsed?, :boolean, required: true
  attr :active, :boolean, default: false

  defp dashboard_nav_item(%{href: "#"} = assigns) do
    ~H"""
    <a
      href="#"
      class={[
        "flex items-center rounded-xl px-3 py-2 text-sm font-medium transition",
        @active && "bg-primary text-primary-content",
        !@active && "text-base-content/70 hover:bg-base-200 hover:text-base-content",
        @collapsed? && "justify-center"
      ]}
    >
      <.icon name={@icon} class="size-5 shrink-0" />
      <span :if={!@collapsed?} class="ml-3">{@label}</span>
    </a>
    """
  end

  defp dashboard_nav_item(assigns) do
    ~H"""
    <.link
      navigate={@href}
      class={[
        "flex items-center rounded-xl px-3 py-2 text-sm font-medium transition",
        @active && "bg-primary text-primary-content",
        !@active && "text-base-content/70 hover:bg-base-200 hover:text-base-content",
        @collapsed? && "justify-center"
      ]}
    >
      <.icon name={@icon} class="size-5 shrink-0" />
      <span :if={!@collapsed?} class="ml-3">{@label}</span>
    </.link>
    """
  end
end
