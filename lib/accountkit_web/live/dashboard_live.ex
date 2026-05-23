defmodule AccountkitWeb.DashboardLive do
  use AccountkitWeb, :live_view

  alias AccountkitWeb.Components.DashboardLayout

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    context = DashboardLayout.dashboard_context(user)

    {:ok,
     socket
     |> assign(:page_title, "Dashboard")
     |> assign(:current_scope, %{user: user})
     |> assign(:dashboard_context, context)
     |> assign(:sidebar_collapsed?, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <DashboardLayout.dashboard_layout
      flash={@flash}
      current_scope={@current_scope}
      dashboard_context={@dashboard_context}
      sidebar_collapsed?={@sidebar_collapsed?}
      page_title={@page_title}
      active_nav={:overview}
    >
      <section class="rounded-2xl border border-base-300 bg-base-100 p-2.5 shadow-sm">
        <p class="text-sm font-semibold text-primary">{@dashboard_context.kicker}</p>
        <h2 class="mt-2 text-2xl font-bold tracking-tight">
          Welcome to {@dashboard_context.logo}
        </h2>
        <p class="mt-3 max-w-2xl text-sm leading-6 text-base-content/70">
          Your control center is ready. Upcoming sections will manage apps, SSO,
          user management, API keys, and rate limits from this dashboard.
        </p>
      </section>

      <section class="mt-4 grid gap-3 md:grid-cols-3">
        <.metric_card label="Applications" value="0" />
        <.metric_card label="Users" value="0" />
        <.metric_card label="API keys" value="0" />
      </section>
    </DashboardLayout.dashboard_layout>
    """
  end

  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_collapsed?, &(!&1))}
  end

  attr :label, :string, required: true
  attr :value, :string, required: true

  defp metric_card(assigns) do
    ~H"""
    <div class="rounded-2xl border border-base-300 bg-base-100 p-2 shadow-sm">
      <p class="text-sm text-base-content/60">{@label}</p>
      <p class="mt-2 text-3xl font-bold">{@value}</p>
    </div>
    """
  end
end
