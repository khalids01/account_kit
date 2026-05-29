defmodule AccountkitWeb.Features.Users.Components do
  use Phoenix.Component

  import AccountkitWeb.Components.UI.Icon, only: [icon: 1]

  attr :users, :list, required: true

  def users_table(assigns) do
    ~H"""
    <div class="hidden overflow-x-auto rounded-2xl border border-base-300 bg-base-100 shadow-sm md:block md:overflow-visible">
      <table class="w-full text-left text-sm">
        <thead class="border-b border-base-300 bg-base-200/50 text-xs uppercase tracking-wide text-base-content/60">
          <tr>
            <th class="px-4 py-3 font-medium">User</th>
            <th class="px-4 py-3 font-medium">Organization</th>
            <th class="px-4 py-3 font-medium">Role</th>
            <th class="px-4 py-3 font-medium">Created</th>
            <th class="px-4 py-3 font-medium"><span class="sr-only">Actions</span></th>
          </tr>
        </thead>
        <tbody class="divide-y divide-base-300">
          <tr :for={user <- @users} id={"dashboard-user-#{user.user.id}"}>
            <td class="px-4 py-3">
              <div class="font-medium">{user.name}</div>
              <div class="text-xs text-base-content/60">{user.email}</div>
            </td>
            <td class="px-4 py-3 text-base-content/70">{organizations_label(user.organizations)}</td>
            <td class="px-4 py-3">
              <.role_badge role={user.role} />
            </td>
            <td class="px-4 py-3 text-base-content/70">{format_datetime(user.created_at)}</td>
            <td class="relative px-4 py-3 text-right">
              <.user_actions_menu id={"user-actions-#{user.user.id}"} />
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  attr :users, :list, required: true

  def users_cards(assigns) do
    ~H"""
    <div class="space-y-3 md:hidden">
      <article
        :for={user <- @users}
        id={"dashboard-user-card-#{user.user.id}"}
        class="rounded-2xl border border-base-300 bg-base-100 p-4 shadow-sm"
      >
        <div class="flex items-start justify-between gap-3">
          <div class="min-w-0">
            <h3 class="truncate font-semibold">{user.name}</h3>
            <p class="mt-1 truncate text-sm text-base-content/70">{user.email}</p>
          </div>
          <.user_actions_menu id={"user-actions-mobile-#{user.user.id}"} />
        </div>

        <div class="mt-4">
          <.role_badge role={user.role} />
        </div>

        <dl class="mt-4 space-y-3 text-sm">
          <div>
            <dt class="text-xs uppercase tracking-wide text-base-content/50">Organization</dt>
            <dd class="mt-1 font-medium">{organizations_label(user.organizations)}</dd>
          </div>
          <div>
            <dt class="text-xs uppercase tracking-wide text-base-content/50">Created</dt>
            <dd class="mt-1 font-medium">{format_datetime(user.created_at)}</dd>
          </div>
        </dl>
      </article>
    </div>
    """
  end

  attr :role, :atom, required: true

  defp role_badge(%{role: :platform_owner} = assigns) do
    ~H"""
    <span class="inline-flex items-center gap-1.5 rounded-full border border-amber-300 bg-amber-50 px-2.5 py-1 text-xs font-semibold text-amber-800 dark:border-amber-400/40 dark:bg-amber-400/10 dark:text-amber-200">
      <.icon name="hero-sparkles" class="size-3.5" />
      <span>Platform owner</span>
    </span>
    """
  end

  defp role_badge(assigns) do
    ~H"""
    <span class="inline-flex items-center rounded-full border border-sky-300 bg-sky-50 px-2.5 py-1 text-xs font-semibold text-sky-800 dark:border-sky-400/40 dark:bg-sky-400/10 dark:text-sky-200">
      Org admin
    </span>
    """
  end

  attr :id, :string, required: true

  defp user_actions_menu(assigns) do
    ~H"""
    <details id={@id} data-user-menu class="group relative">
      <summary
        class="inline-flex size-9 cursor-pointer list-none items-center justify-center rounded-lg border border-base-300 bg-base-100 shadow-sm transition hover:border-primary/60 hover:bg-base-200 focus:outline-none focus:ring-2 focus:ring-primary/40 [&::-webkit-details-marker]:hidden"
        aria-haspopup="menu"
        aria-controls={"#{@id}-content"}
      >
        <span class="sr-only">User actions</span>
        <.icon name="hero-ellipsis-horizontal" class="size-5" />
      </summary>

      <div
        id={"#{@id}-content"}
        role="menu"
        class="absolute right-0 top-full z-50 mt-2 w-52 max-w-[calc(100vw-2rem)] origin-top-right overflow-hidden rounded-xl border border-base-300 bg-base-100 p-2 text-sm shadow-xl"
      >
        <button
          type="button"
          role="menuitem"
          class="flex w-full items-center justify-between gap-3 rounded-lg px-3 py-2 text-base-content/80 transition hover:bg-base-200 hover:text-base-content"
        >
          <span class="flex items-center gap-2">
            <.icon name="hero-no-symbol" class="size-4" />
            <span>Ban user</span>
          </span>
          <span class="h-5 w-9 rounded-full bg-base-300 p-0.5">
            <span class="block size-4 rounded-full bg-base-100 shadow-sm" />
          </span>
        </button>
        <button
          type="button"
          role="menuitem"
          class="flex w-full items-center justify-between gap-3 rounded-lg px-3 py-2 text-base-content/80 transition hover:bg-base-200 hover:text-base-content"
        >
          <span class="flex items-center gap-2">
            <.icon name="hero-archive-box" class="size-4" />
            <span>Archive user</span>
          </span>
          <span class="h-5 w-9 rounded-full bg-base-300 p-0.5">
            <span class="block size-4 rounded-full bg-base-100 shadow-sm" />
          </span>
        </button>
      </div>
    </details>
    """
  end

  defp organizations_label([]), do: "—"

  defp organizations_label(organizations) do
    organizations
    |> Enum.map(& &1.name)
    |> Enum.join(", ")
  end

  defp format_datetime(nil), do: "—"

  defp format_datetime(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%b %-d, %Y")
  end
end
