defmodule AccountkitWeb.Pages.Dashboard.ApiKeysLive do
  use AccountkitWeb, :live_view

  alias Accountkit.Accounts.{ApiKey, Authorization}
  alias AccountkitWeb.Components.Sections.DashboardShell, as: DashboardLayout

  require Ash.Query

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    if Authorization.platform_owner?(user) do
      {:ok,
       socket
       |> assign(:page_title, "API keys")
       |> assign(:current_scope, %{user: user})
       |> assign(:dashboard_context, DashboardLayout.dashboard_context(user))
       |> assign(:sidebar_collapsed?, false)
       |> assign(:created_api_key, nil)
       |> assign(:api_key_form, to_form(%{"expires_on" => default_expires_on()}, as: :api_key))
       |> load_api_keys(user)}
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
      active_nav={:api_keys}
    >
      <section class="space-y-4">
        <div class="flex flex-col gap-1 px-1 sm:px-0">
          <p class="text-sm font-semibold text-primary">Platform</p>
          <h2 class="text-2xl font-semibold tracking-normal">API keys</h2>
          <p class="max-w-2xl text-sm text-base-content/70">
            Personal API keys for your platform owner account.
          </p>
        </div>

        <div
          :if={@created_api_key}
          class="rounded-2xl border border-emerald-300 bg-emerald-50 p-4 text-emerald-950 shadow-sm dark:border-emerald-400/40 dark:bg-emerald-400/10 dark:text-emerald-100"
        >
          <p class="text-sm font-semibold">API key created</p>
          <p class="mt-1 text-sm opacity-80">Copy it now. It will not be shown again.</p>
          <code class="mt-3 block overflow-x-auto rounded-lg bg-base-100 p-3 text-sm text-base-content">
            {@created_api_key}
          </code>
        </div>

        <div class="rounded-2xl border border-base-300 bg-base-100 p-4 shadow-sm">
          <.form
            for={@api_key_form}
            phx-submit="create_api_key"
            class="flex flex-col gap-3 sm:flex-row sm:items-end"
          >
            <div class="sm:max-w-xs">
              <label class="text-sm font-medium">Expires on</label>
              <input
                type="date"
                name={@api_key_form[:expires_on].name}
                value={@api_key_form[:expires_on].value}
                min={Date.utc_today() |> Date.add(1) |> Date.to_iso8601()}
                required
                class="input input-bordered mt-2 w-full"
              />
            </div>

            <button type="submit" class="btn btn-primary sm:mb-0">Create key</button>
          </.form>
        </div>

        <div class="hidden overflow-x-auto rounded-2xl border border-base-300 bg-base-100 shadow-sm md:block">
          <table class="w-full text-left text-sm">
            <thead class="border-b border-base-300 bg-base-200/50 text-xs uppercase tracking-wide text-base-content/60">
              <tr>
                <th class="px-4 py-3 font-medium">Status</th>
                <th class="px-4 py-3 font-medium">Created</th>
                <th class="px-4 py-3 font-medium">Expires</th>
                <th class="px-4 py-3 font-medium"><span class="sr-only">Actions</span></th>
              </tr>
            </thead>
            <tbody class="divide-y divide-base-300">
              <tr :for={api_key <- @api_keys} id={"api-key-#{api_key.id}"}>
                <td class="px-4 py-3"><.status_badge api_key={api_key} /></td>
                <td class="px-4 py-3 text-base-content/70">—</td>
                <td class="px-4 py-3 text-base-content/70">{format_datetime(api_key.expires_at)}</td>
                <td class="px-4 py-3 text-right">
                  <button
                    type="button"
                    phx-click="revoke_api_key"
                    phx-value-id={api_key.id}
                    class="btn btn-error btn-sm"
                  >
                    Revoke
                  </button>
                </td>
              </tr>
              <tr :if={@api_keys == []}>
                <td colspan="4" class="px-4 py-8 text-center text-base-content/60">
                  No API keys yet.
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="space-y-3 md:hidden">
          <article
            :for={api_key <- @api_keys}
            id={"api-key-card-#{api_key.id}"}
            class="rounded-2xl border border-base-300 bg-base-100 p-4 shadow-sm"
          >
            <div class="flex items-start justify-between gap-3">
              <.status_badge api_key={api_key} />
              <button
                type="button"
                phx-click="revoke_api_key"
                phx-value-id={api_key.id}
                class="btn btn-error btn-sm"
              >
                Revoke
              </button>
            </div>

            <dl class="mt-4 grid grid-cols-2 gap-3 text-sm">
              <div>
                <dt class="text-xs uppercase tracking-wide text-base-content/50">Created</dt>
                <dd class="mt-1 font-medium">—</dd>
              </div>
              <div>
                <dt class="text-xs uppercase tracking-wide text-base-content/50">Expires</dt>
                <dd class="mt-1 font-medium">{format_datetime(api_key.expires_at)}</dd>
              </div>
            </dl>
          </article>

          <div
            :if={@api_keys == []}
            class="rounded-2xl border border-base-300 bg-base-100 p-6 text-center text-sm text-base-content/60 shadow-sm"
          >
            No API keys yet.
          </div>
        </div>
      </section>
    </DashboardLayout.dashboard_layout>
    """
  end

  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_collapsed?, &(!&1))}
  end

  def handle_event("create_api_key", %{"api_key" => %{"expires_on" => expires_on}}, socket) do
    user = socket.assigns.current_user

    with {:ok, expires_at} <- expires_at_from_date(expires_on),
         {:ok, api_key} <-
           ApiKey
           |> Ash.Changeset.for_create(
             :create,
             %{user_id: user.id, expires_at: expires_at},
             actor: user
           )
           |> Ash.create() do
      plaintext_api_key = Ash.Resource.get_metadata(api_key, :plaintext_api_key)

      {:noreply,
       socket
       |> put_flash(:info, "API key created.")
       |> assign(:created_api_key, plaintext_api_key)
       |> assign(:api_key_form, to_form(%{"expires_on" => default_expires_on()}, as: :api_key))
       |> load_api_keys(user)}
    else
      _error ->
        {:noreply, put_flash(socket, :error, "Could not create API key.")}
    end
  end

  def handle_event("revoke_api_key", %{"id" => id}, socket) do
    user = socket.assigns.current_user

    with {:ok, api_key} <- get_api_key(id, user),
         :ok <- Ash.destroy(api_key, actor: user) do
      {:noreply,
       socket
       |> put_flash(:info, "API key revoked.")
       |> assign(:created_api_key, nil)
       |> load_api_keys(user)}
    else
      _error ->
        {:noreply, put_flash(socket, :error, "Could not revoke API key.")}
    end
  end

  attr :api_key, ApiKey, required: true

  defp status_badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex rounded-full border px-2.5 py-1 text-xs font-semibold",
      valid?(@api_key) &&
        "border-emerald-300 bg-emerald-50 text-emerald-800 dark:border-emerald-400/40 dark:bg-emerald-400/10 dark:text-emerald-200",
      !valid?(@api_key) &&
        "border-zinc-300 bg-zinc-100 text-zinc-700 dark:border-zinc-500/50 dark:bg-zinc-500/10 dark:text-zinc-200"
    ]}>
      {if valid?(@api_key), do: "Valid", else: "Expired"}
    </span>
    """
  end

  defp load_api_keys(socket, user) do
    api_keys =
      ApiKey
      |> Ash.Query.for_read(:list_for_user, %{user_id: user.id}, actor: user)
      |> Ash.Query.load(:valid)
      |> Ash.read!()

    assign(socket, :api_keys, api_keys)
  end

  defp get_api_key(id, user) do
    user_id = user.id

    ApiKey
    |> Ash.Query.for_read(:read, %{}, actor: user)
    |> Ash.Query.filter(id == ^id and user_id == ^user_id)
    |> Ash.read_one()
  end

  defp expires_at_from_date(date) do
    with {:ok, date} <- Date.from_iso8601(date),
         true <- Date.compare(date, Date.utc_today()) == :gt,
         {:ok, expires_at} <- DateTime.new(date, ~T[23:59:59], "Etc/UTC") do
      {:ok, expires_at}
    else
      _ -> {:error, :invalid_expires_on}
    end
  end

  defp default_expires_on do
    Date.utc_today()
    |> Date.add(30)
    |> Date.to_iso8601()
  end

  defp valid?(%{valid: true}), do: true
  defp valid?(_api_key), do: false

  defp format_datetime(nil), do: "—"

  defp format_datetime(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%b %-d, %Y")
  end
end
