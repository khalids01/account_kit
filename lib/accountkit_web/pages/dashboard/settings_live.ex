defmodule AccountkitWeb.Pages.Dashboard.SettingsLive do
  use AccountkitWeb, :live_view

  alias Accountkit.Accounts.Authorization
  alias Accountkit.RateLimit
  alias AccountkitWeb.Components.Sections.DashboardShell, as: DashboardLayout
  alias AccountkitWeb.Features.RateLimits.Forms, as: RateLimitForms

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    if Authorization.platform_owner?(user) do
      {:ok,
       socket
       |> assign(:page_title, "Settings")
       |> assign(:current_scope, %{user: user})
       |> assign(:dashboard_context, DashboardLayout.dashboard_context(user))
       |> assign(:sidebar_collapsed?, false)
       |> load_policies()}
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
      active_nav={:settings}
    >
      <section class="space-y-4">
        <div class="flex flex-col gap-1 px-1 sm:px-0">
          <p class="text-sm font-semibold text-primary">Platform</p>
          <h2 class="text-2xl font-semibold tracking-normal">Settings</h2>
          <p class="max-w-2xl text-sm text-base-content/70">
            Configure magic link rate limits for sign in and sign up.
          </p>
        </div>

        <div class="space-y-4">
          <.policy_group title="Magic link sign in" rows={@sign_in_policy_rows} />
          <.policy_group title="Magic link sign up" rows={@sign_up_policy_rows} />
        </div>
      </section>
    </DashboardLayout.dashboard_layout>
    """
  end

  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_collapsed?, &(!&1))}
  end

  def handle_event("save_policy", %{"id" => id, "policy" => params}, socket) do
    policy = Enum.find(socket.assigns.policies, &(&1.id == id))
    attrs = RateLimitForms.attrs_from_params(params)

    case Ash.update(policy, attrs, action: :update, authorize?: false) do
      {:ok, _policy} ->
        RateLimit.invalidate_policy_cache()

        {:noreply,
         socket
         |> put_flash(:info, "Saved #{policy.key}.")
         |> load_policies()}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Could not save rate limit policy.")}
    end
  end

  attr :title, :string, required: true
  attr :rows, :list, required: true

  defp policy_group(assigns) do
    ~H"""
    <section class="rounded-2xl border border-base-300 bg-base-100 p-4 shadow-sm">
      <h3 class="text-base font-semibold">{@title}</h3>

      <div class="mt-4 space-y-4">
        <.policy_form :for={row <- @rows} row={row} />
      </div>
    </section>
    """
  end

  attr :row, :map, required: true

  defp policy_form(assigns) do
    ~H"""
    <.form
      for={@row.form}
      phx-submit="save_policy"
      phx-value-id={@row.policy.id}
      class="rounded-xl border border-base-300 bg-base-200/30 p-4"
    >
      <div class="flex flex-col gap-1">
        <h4 class="font-mono text-sm font-semibold text-primary">{@row.policy.key}</h4>
        <p :if={@row.policy.description} class="text-sm text-base-content/70">
          {@row.policy.description}
        </p>
      </div>

      <div class="mt-4 grid gap-4 sm:grid-cols-3">
        <div>
          <label class="text-sm font-medium">Max attempts</label>
          <input
            type="number"
            name={@row.form[:limit].name}
            value={@row.form[:limit].value}
            min="1"
            required
            class="input input-bordered mt-2 w-full"
          />
        </div>

        <div>
          <label class="text-sm font-medium">Window seconds</label>
          <input
            type="number"
            name={@row.form[:period_seconds].name}
            value={@row.form[:period_seconds].value}
            min="1"
            required
            class="input input-bordered mt-2 w-full"
          />
        </div>

        <div class="flex items-end">
          <label class="flex cursor-pointer items-center gap-2">
            <input
              type="checkbox"
              name={@row.form[:enabled].name}
              value="true"
              checked={@row.form[:enabled].value in [true, "true"]}
              class="checkbox checkbox-primary"
            />
            <span class="text-sm font-medium">Enabled</span>
          </label>
        </div>
      </div>

      <div class="mt-4">
        <label class="text-sm font-medium">Description</label>
        <input
          type="text"
          name={@row.form[:description].name}
          value={@row.form[:description].value}
          class="input input-bordered mt-2 w-full"
        />
      </div>

      <div class="mt-4 flex justify-end">
        <button type="submit" class="btn btn-primary btn-sm">Save</button>
      </div>
    </.form>
    """
  end

  defp load_policies(socket) do
    policies = RateLimitForms.list_policies()
    policy_rows = RateLimitForms.policy_rows(policies)

    assign(socket,
      policies: policies,
      sign_in_policy_rows: rows_with_prefix(policy_rows, "magic_link_sign_in"),
      sign_up_policy_rows: rows_with_prefix(policy_rows, "magic_link_sign_up")
    )
  end

  defp rows_with_prefix(policy_rows, prefix) do
    Enum.filter(policy_rows, &String.starts_with?(&1.policy.key, prefix))
  end
end
