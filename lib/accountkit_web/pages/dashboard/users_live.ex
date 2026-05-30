defmodule AccountkitWeb.Pages.Dashboard.UsersLive do
  use AccountkitWeb, :live_view

  alias Accountkit.Accounts.{Authorization, User}
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

        <.tabs
          id="users-tabs"
          variant="nav_pills"
          color="base"
          padding="extra_small"
          rounded="large"
          gap="small"
          class="[&_.tab-nav-pills]:rounded-xl [&_.tab-nav-pills]:border [&_.tab-nav-pills]:border-base-300 [&_.tab-nav-pills]:bg-base-200/50 [&_.tab-nav-pills]:p-1 [&_.tab-trigger]:rounded-lg [&_.tab-trigger]:!p-2 [&_.tab-trigger]:text-base-content/70 [&_.tab-trigger.active-tab]:!bg-primary [&_.tab-trigger.active-tab]:!text-primary-content [&_.tab-trigger.active-tab]:shadow-sm dark:[&_.tab-trigger.active-tab]:!bg-primary dark:[&_.tab-trigger.active-tab]:!text-primary-content"
        >
          <:tab active>Active</:tab>
          <:tab>Archived</:tab>

          <:panel>
            <UserComponents.users_table
              users={@active_users}
              current_user_id={@current_user.id}
              archived?={false}
            />
            <UserComponents.users_cards
              users={@active_users}
              current_user_id={@current_user.id}
              archived?={false}
            />
          </:panel>

          <:panel>
            <UserComponents.users_table
              users={@archived_users}
              current_user_id={@current_user.id}
              archived?={true}
            />
            <UserComponents.users_cards
              users={@archived_users}
              current_user_id={@current_user.id}
              archived?={true}
            />
          </:panel>
        </.tabs>
      </section>
    </DashboardLayout.dashboard_layout>
    """
  end

  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_collapsed?, &(!&1))}
  end

  def handle_event("ban_user", %{"id" => user_id}, socket) do
    manage_user(socket, user_id, :ban, "User banned.")
  end

  def handle_event("unban_user", %{"id" => user_id}, socket) do
    manage_user(socket, user_id, :unban, "User unbanned.")
  end

  def handle_event("archive_user", %{"id" => user_id}, socket) do
    manage_user(socket, user_id, :archive, "User archived.")
  end

  def handle_event("restore_user", %{"id" => user_id}, socket) do
    manage_user(socket, user_id, :restore, "User restored.")
  end

  defp load_data(socket, user) do
    assign(socket,
      active_users: Queries.dashboard_users_for_platform(user, archived?: false),
      archived_users: Queries.dashboard_users_for_platform(user, archived?: true)
    )
  end

  defp manage_user(socket, user_id, action, success_message) do
    actor = socket.assigns.current_user

    with {:ok, user} <- get_user(user_id, actor),
         {:ok, _user} <- update_user(user, action, actor) do
      {:noreply,
       socket
       |> put_flash(:info, success_message)
       |> load_data(actor)}
    else
      _error ->
        {:noreply, put_flash(socket, :error, "Could not update that user.")}
    end
  end

  defp get_user(user_id, actor) do
    User
    |> Ash.Query.for_read(:get_by_id, %{id: user_id}, actor: actor)
    |> Ash.read_one()
  end

  defp update_user(user, action, actor) do
    user
    |> Ash.Changeset.for_update(action, %{}, actor: actor)
    |> Ash.update()
  end
end
