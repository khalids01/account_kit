defmodule AccountkitWeb.Features.EndUsers.Components do
  use Phoenix.Component
  use AccountkitWeb.Components.MishkaComponents

  attr :filters, :map, required: true
  attr :organizations, :list, required: true
  attr :platform_owner?, :boolean, required: true
  attr :auth_methods, :list, required: true

  def filters(assigns) do
    ~H"""
    <form
      phx-change="filter"
      class="space-y-4 rounded-lg border border-base-300 bg-base-100 p-4 shadow-sm"
    >
      <input type="hidden" name="filters[tab]" value={@filters["tab"]} />

      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <.search_field
          id="end-users-search"
          name="filters[search]"
          value={@filters["search"]}
          label="Search"
          placeholder="Name, email, or phone"
          size="small"
          space="small"
          variant="base"
          phx-debounce="600"
        >
          <:start_section>
            <.icon name="hero-magnifying-glass" class="size-4 opacity-60" />
          </:start_section>
        </.search_field>

        <.native_select
          :if={@platform_owner? or length(@organizations) > 1}
          id="end-users-organization"
          name="filters[organization_id]"
          label="Organization"
          size="small"
          space="small"
          variant="base"
        >
          <:option value="all" selected={@filters["organization_id"] == "all"}>
            All organizations
          </:option>
          <:option
            :for={organization <- @organizations}
            value={organization.id}
            selected={@filters["organization_id"] == organization.id}
          >
            {organization.name}
          </:option>
        </.native_select>

        <.native_select
          id="end-users-status"
          name="filters[status]"
          label="Status"
          size="small"
          space="small"
          variant="base"
        >
          <:option value="all" selected={@filters["status"] == "all"}>All</:option>
          <:option value="active" selected={@filters["status"] == "active"}>Active</:option>
          <:option value="banned" selected={@filters["status"] == "banned"}>Banned</:option>
        </.native_select>

        <.native_select
          id="end-users-sort"
          name="filters[sort]"
          label="Sort"
          size="small"
          space="small"
          variant="base"
        >
          <:option value="newest" selected={@filters["sort"] == "newest"}>Newest first</:option>
          <:option value="oldest" selected={@filters["sort"] == "oldest"}>Oldest first</:option>
        </.native_select>
      </div>

      <div class="space-y-2 border-t border-base-300 pt-4">
        <label class="block text-sm font-semibold leading-6 text-base-text-light dark:text-base-text-dark">
          Auth types
        </label>
        <.group_checkbox
          id="end-users-auth-methods"
          name="filters[auth_methods][]"
          variation="horizontal"
          size="small"
          space="small"
          color="natural"
        >
          <:checkbox
            :for={method <- @auth_methods}
            value={method}
            checked={method in @filters["auth_methods"]}
          >
            {auth_label(method)}
          </:checkbox>
        </.group_checkbox>
      </div>
    </form>
    """
  end

  attr :filters, :map, required: true
  attr :counts, :map, required: true

  def tabs(assigns) do
    ~H"""
    <div class="inline-flex rounded-lg border border-base-300 bg-base-100 p-1 shadow-sm">
      <button
        type="button"
        phx-click="switch_tab"
        phx-value-tab="users"
        class={tab_class(@filters["tab"] == "users")}
      >
        Users <span class="ml-1 text-xs opacity-70">({@counts.users})</span>
      </button>
      <button
        type="button"
        phx-click="switch_tab"
        phx-value-tab="archived"
        class={tab_class(@filters["tab"] == "archived")}
      >
        Archived <span class="ml-1 text-xs opacity-70">({@counts.archived})</span>
      </button>
    </div>
    """
  end

  attr :selected_count, :integer, required: true
  attr :tab, :string, required: true

  def bulk_toolbar(assigns) do
    ~H"""
    <div
      :if={@selected_count > 0}
      class="flex flex-col gap-2 rounded-lg border border-primary/30 bg-primary/10 p-3 text-sm sm:flex-row sm:items-center sm:justify-between"
    >
      <div class="font-medium">{@selected_count} selected</div>
      <div class="flex flex-wrap gap-2">
        <button
          :if={@tab == "users"}
          type="button"
          phx-click="request_bulk_action"
          phx-value-action="ban"
          class="btn btn-sm"
        >
          Ban
        </button>
        <button
          :if={@tab == "users"}
          type="button"
          phx-click="request_bulk_action"
          phx-value-action="unban"
          class="btn btn-sm"
        >
          Unban
        </button>
        <button
          :if={@tab == "users"}
          type="button"
          phx-click="request_bulk_action"
          phx-value-action="archive"
          class="btn btn-sm btn-warning"
        >
          Archive
        </button>
        <button
          :if={@tab == "archived"}
          type="button"
          phx-click="request_bulk_action"
          phx-value-action="restore"
          class="btn btn-sm"
        >
          Restore
        </button>
        <button
          :if={@tab == "archived"}
          type="button"
          phx-click="request_bulk_action"
          phx-value-action="delete"
          class="btn btn-sm btn-error"
        >
          Delete
        </button>
        <button type="button" phx-click="clear_selection" class="btn btn-sm btn-ghost">Clear</button>
      </div>
    </div>
    """
  end

  attr :rows, :list, required: true
  attr :selected_ids, :any, required: true
  attr :tab, :string, required: true

  def table(assigns) do
    ~H"""
    <div class="hidden overflow-x-auto rounded-lg border border-base-300 bg-base-100 shadow-sm xl:block xl:overflow-visible">
      <table class="w-full text-left text-sm">
        <thead class="border-b border-base-300 bg-base-200/60 text-xs uppercase text-base-content/60">
          <tr>
            <th class="w-10 px-3 py-3">
              <input type="checkbox" phx-click="toggle_page_selection" class="checkbox checkbox-sm" />
            </th>
            <th class="px-3 py-3 font-medium">User</th>
            <th class="px-3 py-3 font-medium">Phone</th>
            <th class="px-3 py-3 font-medium">Organization</th>
            <th class="px-3 py-3 font-medium">Application</th>
            <th class="px-3 py-3 font-medium">Auth</th>
            <th class="px-3 py-3 font-medium">Status</th>
            <th class="px-3 py-3 font-medium">Created</th>
            <th class="px-3 py-3 font-medium"><span class="sr-only">Actions</span></th>
          </tr>
        </thead>
        <tbody class="divide-y divide-base-300">
          <tr :for={row <- @rows} id={"end-user-#{row.id}"}>
            <td class="px-3 py-3">
              <input
                type="checkbox"
                phx-click="toggle_select"
                phx-value-id={row.id}
                checked={selected?(@selected_ids, row.id)}
                class="checkbox checkbox-sm"
              />
            </td>
            <td class="px-3 py-3">
              <div class="font-medium">{row.name}</div>
              <div class="text-xs text-base-content/60">{row.email}</div>
            </td>
            <td class="px-3 py-3 text-base-content/70">{row.phone || "—"}</td>
            <td class="px-3 py-3 text-base-content/70">{row.organization.name}</td>
            <td class="px-3 py-3 text-base-content/70">{row.application.name}</td>
            <td class="px-3 py-3"><.auth_badges methods={row.auth_methods} /></td>
            <td class="px-3 py-3"><.status_badge row={row} /></td>
            <td class="px-3 py-3 text-base-content/70">{format_date(row.created_at)}</td>
            <td class="relative px-3 py-3 text-right">
              <.actions_menu id={"end-user-actions-#{row.id}"} row={row} tab={@tab} />
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  attr :rows, :list, required: true
  attr :selected_ids, :any, required: true
  attr :tab, :string, required: true

  def cards(assigns) do
    ~H"""
    <div class="space-y-3 xl:hidden">
      <article
        :for={row <- @rows}
        id={"end-user-card-#{row.id}"}
        class="rounded-lg border border-base-300 bg-base-100 p-4 shadow-sm"
      >
        <div class="flex items-start justify-between gap-3">
          <div class="flex min-w-0 gap-3">
            <input
              type="checkbox"
              phx-click="toggle_select"
              phx-value-id={row.id}
              checked={selected?(@selected_ids, row.id)}
              class="checkbox checkbox-sm mt-1"
            />
            <div class="min-w-0">
              <h3 class="truncate font-semibold">{row.name}</h3>
              <p class="truncate text-sm text-base-content/70">{row.email}</p>
            </div>
          </div>
          <.actions_menu id={"end-user-actions-card-#{row.id}"} row={row} tab={@tab} />
        </div>
        <div class="mt-3 flex flex-wrap gap-1.5">
          <.status_badge row={row} />
          <.auth_badges methods={row.auth_methods} />
        </div>
        <dl class="mt-4 grid gap-3 text-sm sm:grid-cols-2">
          <div>
            <dt class="text-xs text-base-content/50">Phone</dt>
            <dd>{row.phone || "—"}</dd>
          </div>
          <div>
            <dt class="text-xs text-base-content/50">Organization</dt>
            <dd>{row.organization.name}</dd>
          </div>
          <div>
            <dt class="text-xs text-base-content/50">Application</dt>
            <dd>{row.application.name}</dd>
          </div>
          <div>
            <dt class="text-xs text-base-content/50">Created</dt>
            <dd>{format_date(row.created_at)}</dd>
          </div>
        </dl>
      </article>
    </div>
    """
  end

  attr :pagination, :map, required: true

  def pagination(assigns) do
    ~H"""
    <div class="flex flex-col gap-3 text-sm sm:flex-row sm:items-center sm:justify-between">
      <p class="text-base-content/60">
        Showing {length(@pagination.entries)} of {@pagination.total_entries}
      </p>
      <div class="flex flex-wrap items-center gap-1">
        <button
          type="button"
          phx-click="page"
          phx-value-page={max(@pagination.page - 1, 1)}
          disabled={@pagination.page <= 1}
          class="btn btn-sm btn-ghost"
        >
          <.icon name="hero-chevron-left" class="size-4" />
        </button>
        <%= for page <- @pagination.pages do %>
          <span :if={page == :ellipsis} class="px-2 text-base-content/50">...</span>
          <button
            :if={page != :ellipsis}
            type="button"
            phx-click="page"
            phx-value-page={page}
            class={[
              "btn btn-sm",
              page == @pagination.page && "btn-primary",
              page != @pagination.page && "btn-ghost"
            ]}
          >
            {page}
          </button>
        <% end %>
        <button
          type="button"
          phx-click="page"
          phx-value-page={min(@pagination.page + 1, @pagination.total_pages)}
          disabled={@pagination.page >= @pagination.total_pages}
          class="btn btn-sm btn-ghost"
        >
          <.icon name="hero-chevron-right" class="size-4" />
        </button>
      </div>
    </div>
    """
  end

  attr :row, :map, required: true

  def view_modal(assigns) do
    ~H"""
    <.modal_shell title="End user details">
      <div class="space-y-4">
        <div>
          <h3 class="text-xl font-semibold">{@row.name}</h3>
          <p class="text-sm text-base-content/70">{@row.email}</p>
        </div>
        <dl class="grid gap-3 text-sm sm:grid-cols-2">
          <.detail label="Phone" value={@row.phone || "—"} />
          <.detail label="Status" value={status_label(@row.status)} />
          <.detail label="Organization" value={@row.organization.name} />
          <.detail label="Application" value={@row.application.name} />
          <.detail label="Auth methods" value={Enum.map_join(@row.auth_methods, ", ", &auth_label/1)} />
          <.detail label="Created" value={format_date(@row.created_at)} />
        </dl>
      </div>
    </.modal_shell>
    """
  end

  attr :form, :any, required: true
  attr :row, :map, required: true

  def edit_modal(assigns) do
    ~H"""
    <.modal_shell title="Edit end user">
      <.form for={@form} phx-submit="save_edit" class="space-y-4">
        <div>
          <label class="text-sm font-medium">Name</label>
          <input
            name={@form["name"].name}
            value={@form["name"].value}
            class="input input-bordered mt-2 w-full"
          />
        </div>
        <div>
          <label class="text-sm font-medium">Phone</label>
          <input
            name={@form["phone"].name}
            value={@form["phone"].value}
            class="input input-bordered mt-2 w-full"
          />
        </div>
        <div class="flex justify-end gap-2">
          <button type="button" phx-click="close_modal" class="btn btn-ghost">Cancel</button>
          <button type="submit" class="btn btn-primary">Save changes</button>
        </div>
      </.form>
    </.modal_shell>
    """
  end

  attr :confirmation, :map, required: true

  def confirmation_modal(assigns) do
    ~H"""
    <.modal_shell title={@confirmation.title}>
      <p class="text-sm text-base-content/70">{@confirmation.message}</p>
      <div class="mt-6 flex justify-end gap-2">
        <button type="button" phx-click="close_modal" class="btn btn-ghost">Cancel</button>
        <button
          type="button"
          phx-click="confirm_action"
          class={[
            "btn",
            @confirmation.danger? && "btn-error",
            !@confirmation.danger? && "btn-primary"
          ]}
        >
          {@confirmation.confirm_label}
        </button>
      </div>
    </.modal_shell>
    """
  end

  attr :id, :string, required: true
  attr :row, :map, required: true
  attr :tab, :string, required: true

  defp actions_menu(assigns) do
    ~H"""
    <details id={@id} data-user-menu class="group relative">
      <summary
        class="inline-flex size-9 cursor-pointer list-none items-center justify-center rounded-lg border border-base-300 bg-base-100 shadow-sm transition hover:border-primary/60 hover:bg-base-200 focus:outline-none focus:ring-2 focus:ring-primary/40 [&::-webkit-details-marker]:hidden"
        aria-haspopup="menu"
        aria-controls={"#{@id}-content"}
      >
        <span class="sr-only">End user actions</span>
        <.icon name="hero-ellipsis-horizontal" class="size-5" />
      </summary>

      <div
        id={"#{@id}-content"}
        role="menu"
        class="absolute right-0 top-full z-50 mt-2 w-56 max-w-[calc(100vw-2rem)] origin-top-right overflow-hidden rounded-xl border border-base-300 bg-base-100 p-2 text-sm shadow-xl"
      >
        <.menu_button icon="hero-eye" label="View" event="view_user" id={@row.id} />
        <.menu_button icon="hero-pencil-square" label="Edit" event="edit_user" id={@row.id} />
        <.menu_button
          :if={@tab == "users"}
          icon={if @row.banned?, do: "hero-play-circle", else: "hero-no-symbol"}
          label={if @row.banned?, do: "Unban", else: "Ban"}
          event="request_action"
          action={if @row.banned?, do: "unban", else: "ban"}
          id={@row.id}
        />
        <.menu_button
          :if={@tab == "users"}
          icon="hero-archive-box"
          label="Archive"
          event="request_action"
          action="archive"
          id={@row.id}
        />
        <.menu_button
          :if={@tab == "archived"}
          icon="hero-arrow-uturn-left"
          label="Restore"
          event="request_action"
          action="restore"
          id={@row.id}
        />
        <.menu_button
          :if={@tab == "archived"}
          icon="hero-trash"
          label="Permanently delete"
          event="request_action"
          action="delete"
          id={@row.id}
          danger
        />
      </div>
    </details>
    """
  end

  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :event, :string, required: true
  attr :id, :string, required: true
  attr :action, :string, default: nil
  attr :danger, :boolean, default: false

  defp menu_button(assigns) do
    ~H"""
    <button
      type="button"
      role="menuitem"
      phx-click={@event}
      phx-value-id={@id}
      phx-value-action={@action}
      class={[
        "flex w-full items-center gap-2 rounded-md px-3 py-2 text-left hover:bg-base-200",
        @danger && "text-error"
      ]}
    >
      <.icon name={@icon} class="size-4" />
      <span>{@label}</span>
    </button>
    """
  end

  attr :methods, :list, required: true

  defp auth_badges(assigns) do
    ~H"""
    <div class="flex flex-wrap gap-1">
      <span
        :for={method <- @methods}
        class="rounded-full border border-sky-300 bg-sky-50 px-2 py-0.5 text-xs font-medium text-sky-800 dark:border-sky-400/40 dark:bg-sky-400/10 dark:text-sky-200"
      >
        {auth_label(method)}
      </span>
    </div>
    """
  end

  attr :row, :map, required: true

  defp status_badge(assigns) do
    ~H"""
    <span class={status_class(@row.status)}>{status_label(@row.status)}</span>
    """
  end

  attr :label, :string, required: true
  attr :value, :string, required: true

  defp detail(assigns) do
    ~H"""
    <div class="rounded-lg border border-base-300 p-3">
      <dt class="text-xs uppercase text-base-content/50">{@label}</dt>
      <dd class="mt-1 font-medium">{@value}</dd>
    </div>
    """
  end

  slot :inner_block, required: true
  attr :title, :string, required: true

  defp modal_shell(assigns) do
    ~H"""
    <div class="fixed inset-0 z-50 overflow-y-auto bg-black/50 p-4 backdrop-blur-sm">
      <div class="mx-auto my-20 max-w-2xl rounded-lg border border-base-300 bg-base-100 p-5 shadow-2xl">
        <div class="mb-4 flex items-center justify-between gap-3">
          <h2 class="text-lg font-semibold">{@title}</h2>
          <button type="button" phx-click="close_modal" class="btn btn-ghost btn-sm btn-square">
            <.icon name="hero-x-mark" class="size-5" />
          </button>
        </div>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  defp selected?(selected_ids, id), do: MapSet.member?(selected_ids, id)

  defp tab_class(active?) do
    [
      "rounded-md px-3 py-1.5 text-sm font-medium transition",
      active? && "bg-primary text-primary-content shadow-sm",
      !active? && "text-base-content/70 hover:bg-base-200 hover:text-base-content"
    ]
  end

  defp status_class(:active),
    do:
      "rounded-full border border-emerald-300 bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-800 dark:border-emerald-400/40 dark:bg-emerald-400/10 dark:text-emerald-200"

  defp status_class(:banned),
    do:
      "rounded-full border border-rose-300 bg-rose-50 px-2.5 py-1 text-xs font-semibold text-rose-800 dark:border-rose-400/40 dark:bg-rose-400/10 dark:text-rose-200"

  defp status_class(:archived),
    do:
      "rounded-full border border-zinc-300 bg-zinc-100 px-2.5 py-1 text-xs font-semibold text-zinc-700 dark:border-zinc-500/50 dark:bg-zinc-500/10 dark:text-zinc-200"

  defp status_label(:active), do: "Active"
  defp status_label(:banned), do: "Banned"
  defp status_label(:archived), do: "Archived"

  defp auth_label("magic_link"), do: "Magic link"
  defp auth_label("oauth"), do: "OAuth"

  defp auth_label(method),
    do: method |> to_string() |> String.replace("_", " ") |> String.capitalize()

  defp format_date(nil), do: "—"
  defp format_date(%DateTime{} = datetime), do: Calendar.strftime(datetime, "%b %-d, %Y")
end
