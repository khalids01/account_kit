defmodule AccountkitWeb.DashboardLive do
  use AccountkitWeb, :live_view

  alias Accountkit.Accounts.Authorization

  @impl true
  def mount(_params, _session, socket) do
    context = dashboard_context(socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:page_title, "Dashboard")
     |> assign(:current_scope, %{user: socket.assigns.current_user})
     |> assign(:dashboard_context, context)
     |> assign(:sidebar_collapsed?, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
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
              collapsed?={@sidebar_collapsed?}
              active
            />
            <.dashboard_nav_item
              icon="hero-users"
              label="Users"
              collapsed?={@sidebar_collapsed?}
            />
            <.dashboard_nav_item
              icon="hero-key"
              label="API keys"
              collapsed?={@sidebar_collapsed?}
            />
            <.dashboard_nav_item
              icon="hero-cog-6-tooth"
              label="Settings"
              collapsed?={@sidebar_collapsed?}
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
                <h1 class="text-lg font-semibold">Dashboard</h1>
                <p class="text-xs text-base-content/60">{@dashboard_context.label}</p>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <.theme_toggle />
              <.user_menu id="dashboard-user-menu" current_scope={@current_scope} />
            </div>
          </header>

          <main class="p-4 sm:p-6">
            <section class="rounded-2xl border border-base-300 bg-base-100 p-6 shadow-sm">
              <p class="text-sm font-semibold text-primary">{@dashboard_context.kicker}</p>
              <h2 class="mt-2 text-2xl font-bold tracking-tight">
                Welcome to {@dashboard_context.logo}
              </h2>
              <p class="mt-3 max-w-2xl text-sm leading-6 text-base-content/70">
                Your control center is ready. Upcoming sections will manage apps, SSO,
                user management, API keys, and rate limits from this dashboard.
              </p>
            </section>

            <section class="mt-6 grid gap-4 md:grid-cols-3">
              <.metric_card label="Applications" value="0" />
              <.metric_card label="Users" value="0" />
              <.metric_card label="API keys" value="0" />
            </section>
          </main>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_collapsed?, &(!&1))}
  end

  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :collapsed?, :boolean, required: true
  attr :active, :boolean, default: false

  defp dashboard_nav_item(assigns) do
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

  attr :label, :string, required: true
  attr :value, :string, required: true

  defp metric_card(assigns) do
    ~H"""
    <div class="rounded-2xl border border-base-300 bg-base-100 p-5 shadow-sm">
      <p class="text-sm text-base-content/60">{@label}</p>
      <p class="mt-2 text-3xl font-bold">{@value}</p>
    </div>
    """
  end

  defp dashboard_context(user) do
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
end
