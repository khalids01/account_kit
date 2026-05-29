defmodule AccountkitWeb.Features.Organizations.Components do
  use Phoenix.Component

  import AccountkitWeb.Components.UI.Icon, only: [icon: 1]

  attr :organizations, :list, required: true

  def organizations_table(assigns) do
    ~H"""
    <div class="hidden overflow-x-auto rounded-2xl border border-base-300 bg-base-100 shadow-sm md:block md:overflow-visible">
      <table class="w-full text-left text-sm">
        <thead class="border-b border-base-300 bg-base-200/50 text-xs uppercase tracking-wide text-base-content/60">
          <tr>
            <th class="px-4 py-3 font-medium">Name</th>
            <th class="px-4 py-3 font-medium">Owner</th>
            <th class="px-4 py-3 font-medium">End users</th>
            <th class="px-4 py-3 font-medium">Created</th>
            <th class="px-4 py-3 font-medium"><span class="sr-only">Actions</span></th>
          </tr>
        </thead>
        <tbody class="divide-y divide-base-300">
          <tr :for={org <- @organizations} id={"organization-#{org.id}"}>
            <td class="px-4 py-3 font-medium">{org.name}</td>
            <td class="px-4 py-3 text-base-content/70">{org_admin_label(org)}</td>
            <td class="px-4 py-3 text-base-content/70">{org.end_users_count}</td>
            <td class="px-4 py-3 text-base-content/70">{format_datetime(org.created_at)}</td>
            <td class="relative px-4 py-3 text-right">
              <.org_actions_menu id={"org-actions-#{org.id}"} />
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  attr :organizations, :list, required: true

  def organizations_cards(assigns) do
    ~H"""
    <div class="space-y-3 md:hidden">
      <article
        :for={org <- @organizations}
        id={"organization-card-#{org.id}"}
        class="rounded-2xl border border-base-300 bg-base-100 p-4 shadow-sm"
      >
        <div class="flex items-start justify-between gap-3">
          <div class="min-w-0">
            <h3 class="truncate font-semibold">{org.name}</h3>
            <p class="mt-1 text-sm text-base-content/70">Owner: {org_admin_label(org)}</p>
          </div>
          <.org_actions_menu id={"org-actions-mobile-#{org.id}"} />
        </div>
        <dl class="mt-4 grid grid-cols-2 gap-3 text-sm">
          <div>
            <dt class="text-xs uppercase tracking-wide text-base-content/50">End users</dt>
            <dd class="mt-1 font-medium">{org.end_users_count}</dd>
          </div>
          <div>
            <dt class="text-xs uppercase tracking-wide text-base-content/50">Created</dt>
            <dd class="mt-1 font-medium">{format_datetime(org.created_at)}</dd>
          </div>
        </dl>
      </article>
    </div>
    """
  end

  attr :memberships, :list, required: true

  def owners_table(assigns) do
    ~H"""
    <div class="hidden overflow-hidden rounded-2xl border border-base-300 bg-base-100 shadow-sm md:block">
      <table class="w-full text-left text-sm">
        <thead class="border-b border-base-300 bg-base-200/50 text-xs uppercase tracking-wide text-base-content/60">
          <tr>
            <th class="px-4 py-3 font-medium">Name</th>
            <th class="px-4 py-3 font-medium">Email</th>
            <th class="px-4 py-3 font-medium">Organization</th>
            <th class="px-4 py-3 font-medium">Created</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-base-300">
          <tr :for={membership <- @memberships} id={"owner-#{membership.id}"}>
            <td class="px-4 py-3 font-medium">{owner_name(membership)}</td>
            <td class="px-4 py-3 text-base-content/70">{owner_email(membership)}</td>
            <td class="px-4 py-3 text-base-content/70">{membership.organization.name}</td>
            <td class="px-4 py-3 text-base-content/70">{format_datetime(membership.created_at)}</td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  attr :memberships, :list, required: true

  def owners_cards(assigns) do
    ~H"""
    <div class="space-y-3 md:hidden">
      <article
        :for={membership <- @memberships}
        id={"owner-card-#{membership.id}"}
        class="rounded-2xl border border-base-300 bg-base-100 p-4 shadow-sm"
      >
        <h3 class="font-semibold">{owner_name(membership)}</h3>
        <p class="mt-1 truncate text-sm text-base-content/70">{owner_email(membership)}</p>
        <dl class="mt-4 space-y-3 text-sm">
          <div>
            <dt class="text-xs uppercase tracking-wide text-base-content/50">Organization</dt>
            <dd class="mt-1 font-medium">{membership.organization.name}</dd>
          </div>
          <div>
            <dt class="text-xs uppercase tracking-wide text-base-content/50">Created</dt>
            <dd class="mt-1 font-medium">{format_datetime(membership.created_at)}</dd>
          </div>
        </dl>
      </article>
    </div>
    """
  end

  attr :id, :string, required: true

  defp org_actions_menu(assigns) do
    ~H"""
    <details id={@id} data-user-menu class="group relative">
      <summary
        class="inline-flex size-9 cursor-pointer list-none items-center justify-center rounded-lg border border-base-300 bg-base-100 shadow-sm transition hover:border-primary/60 hover:bg-base-200 focus:outline-none focus:ring-2 focus:ring-primary/40 [&::-webkit-details-marker]:hidden"
        aria-haspopup="menu"
        aria-controls={"#{@id}-content"}
      >
        <span class="sr-only">Organization actions</span>
        <.icon name="hero-ellipsis-horizontal" class="size-5" />
      </summary>

      <div
        id={"#{@id}-content"}
        role="menu"
        class="absolute right-0 top-full z-50 mt-2 w-48 max-w-[calc(100vw-2rem)] origin-top-right overflow-hidden rounded-xl border border-base-300 bg-base-100 p-2 text-sm shadow-xl"
      >
        <button
          type="button"
          role="menuitem"
          class="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-base-content/80 transition hover:bg-base-200 hover:text-base-content"
        >
          <.icon name="hero-eye" class="size-4" />
          <span>View</span>
        </button>
        <button
          type="button"
          role="menuitem"
          class="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-base-content/80 transition hover:bg-base-200 hover:text-base-content"
        >
          <.icon name="hero-pencil-square" class="size-4" />
          <span>Edit</span>
        </button>
        <button
          type="button"
          role="menuitem"
          class="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-base-content/80 transition hover:bg-base-200 hover:text-base-content"
        >
          <.icon name="hero-no-symbol" class="size-4" />
          <span>Suspend</span>
        </button>
      </div>
    </details>
    """
  end

  defp org_admin_label(%{memberships: memberships}) when is_list(memberships) do
    memberships
    |> Enum.find(&(&1.role == :org_admin))
    |> case do
      %{user: user} -> owner_display_name(user)
      _ -> "—"
    end
  end

  defp org_admin_label(_), do: "—"

  defp owner_name(%{user: user}), do: owner_display_name(user)
  defp owner_name(_), do: "—"

  defp owner_email(%{user: %{email: email}}) when not is_nil(email), do: to_string(email)
  defp owner_email(_), do: "—"

  defp owner_display_name(%{name: name}) when is_binary(name) and name != "", do: name
  defp owner_display_name(%{email: email}) when not is_nil(email), do: to_string(email)
  defp owner_display_name(_), do: "—"

  defp format_datetime(nil), do: "—"

  defp format_datetime(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%b %-d, %Y")
  end
end
