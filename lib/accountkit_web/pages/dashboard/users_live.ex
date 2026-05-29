defmodule AccountkitWeb.Pages.Dashboard.UsersLive do
  use AccountkitWeb, :live_view

  alias Accountkit.Accounts.Authorization
  alias AccountkitWeb.Components.Sections.DashboardShell, as: DashboardLayout
  alias AccountkitWeb.Features.Users.Components, as: UserComponents
  alias AccountkitWeb.Features.Users.Queries

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    if Authorization.platform_owner?(user) do
      {:ok,
       socket
       |> assign(:page_title, "Users")
       |> assign(:current_scope, %{user: user})
       |> assign(:dashboard_context, DashboardLayout.dashboard_context(user))
       |> assign(:sidebar_collapsed?, false)
       |> load_data(user)}
    else
      {:ok, push_navigate(socket, to: ~p"/dashboard")}
    end
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
      active_nav={:users}
    >
      <section class="space-y-4">
        <div class="flex flex-col gap-1 px-1 sm:px-0">
          <p class="text-sm font-semibold text-primary">Platform</p>
          <h2 class="text-2xl font-semibold tracking-normal">Users</h2>
          <p class="max-w-2xl text-sm text-base-content/70">
            Platform owners and organization admins with dashboard access.
          </p>
        </div>

        <UserComponents.users_table users={@users} />
        <UserComponents.users_cards users={@users} />
      </section>
    </DashboardLayout.dashboard_layout>
    """
  end

  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_collapsed?, &(!&1))}
  end

  defp load_data(socket, user) do
    assign(socket, :users, Queries.dashboard_users_for_platform(user))
  end
end
