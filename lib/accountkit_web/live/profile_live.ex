defmodule AccountkitWeb.ProfileLive do
  use AccountkitWeb, :live_view

  alias Accountkit.Accounts.Authorization

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Profile")
     |> assign(:current_scope, %{user: socket.assigns.current_user})
     |> assign(:role_summary, role_summary(socket.assigns.current_user))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.home flash={@flash} current_scope={@current_scope}>
      <section class="mx-auto min-h-[calc(100vh-4rem)] max-w-3xl px-6 py-12">
        <div class="rounded-2xl border border-base-300 bg-base-100 p-8 shadow-sm">
          <p class="text-sm font-semibold text-primary">Profile</p>
          <h1 class="mt-2 text-3xl font-bold tracking-tight">Your account</h1>

          <dl class="mt-8 grid gap-4 sm:grid-cols-2">
            <div class="rounded-xl border border-base-300 p-4">
              <dt class="text-sm text-base-content/60">Name</dt>
              <dd class="mt-1 font-medium">{@current_user.name || "Not set"}</dd>
            </div>
            <div class="rounded-xl border border-base-300 p-4">
              <dt class="text-sm text-base-content/60">Email</dt>
              <dd class="mt-1 truncate font-medium">{to_string(@current_user.email)}</dd>
            </div>
            <div class="rounded-xl border border-base-300 p-4 sm:col-span-2">
              <dt class="text-sm text-base-content/60">Access</dt>
              <dd class="mt-1 font-medium">{@role_summary}</dd>
            </div>
          </dl>
        </div>
      </section>
    </Layouts.home>
    """
  end

  defp role_summary(user) do
    cond do
      Authorization.platform_owner?(user) ->
        "Platform owner"

      membership = Authorization.first_org_membership(user) ->
        "Organization admin for #{membership.organization.name}"

      true ->
        "No organization yet"
    end
  end
end
