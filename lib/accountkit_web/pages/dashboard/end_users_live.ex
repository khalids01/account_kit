defmodule AccountkitWeb.Pages.Dashboard.EndUsersLive do
  use AccountkitWeb, :live_view

  alias AccountkitWeb.Components.Sections.DashboardShell, as: DashboardLayout
  alias AccountkitWeb.Features.EndUsers.{Actions, Components, Forms, Queries}

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    filters = Forms.default_filters()

    {:ok,
     socket
     |> assign(:page_title, "End Users")
     |> assign(:current_scope, %{user: user})
     |> assign(:dashboard_context, DashboardLayout.dashboard_context(user))
     |> assign(:sidebar_collapsed?, false)
     |> assign(:filters, filters)
     |> assign(:selected_ids, MapSet.new())
     |> assign(:modal, nil)
     |> assign(:modal_row, nil)
     |> assign(:edit_form, nil)
     |> assign(:confirmation, nil)
     |> load_data()}
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
      active_nav={:end_users}
    >
      <section class="space-y-4">
        <div class="flex flex-col gap-3 px-1 sm:flex-row sm:items-end sm:justify-between sm:px-0">
          <div>
            <p class="text-sm font-semibold text-primary">Application SSO</p>
            <h2 class="text-2xl font-semibold tracking-normal">End Users</h2>
            <p class="max-w-2xl text-sm text-base-content/70">
              Manage client-application users separately from AccountKit platform users.
            </p>
          </div>
          <Components.tabs filters={@filters} counts={@counts} />
        </div>

        <Components.filters
          filters={@filters}
          organizations={@organizations}
          platform_owner?={@platform_owner?}
          auth_methods={@auth_methods}
        />

        <Components.bulk_toolbar
          selected_count={MapSet.size(@selected_ids)}
          tab={@filters["tab"]}
        />

        <div
          :if={@pagination.entries == []}
          class="rounded-lg border border-dashed border-base-300 bg-base-100 p-8 text-center text-sm text-base-content/60"
        >
          No end users match these filters.
        </div>

        <Components.table
          :if={@pagination.entries != []}
          rows={@pagination.entries}
          selected_ids={@selected_ids}
          tab={@filters["tab"]}
        />
        <Components.cards
          :if={@pagination.entries != []}
          rows={@pagination.entries}
          selected_ids={@selected_ids}
          tab={@filters["tab"]}
        />

        <Components.pagination pagination={@pagination} />

        <Components.view_modal :if={@modal == :view and @modal_row} row={@modal_row} />
        <Components.edit_modal
          :if={@modal == :edit and @modal_row}
          row={@modal_row}
          form={@edit_form}
        />
        <Components.confirmation_modal
          :if={@modal == :confirm and @confirmation}
          confirmation={@confirmation}
        />
      </section>
    </DashboardLayout.dashboard_layout>
    """
  end

  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_collapsed?, &(!&1))}
  end

  def handle_event("filter", %{"filters" => params}, socket) do
    filters =
      params
      |> Forms.normalize_filters(socket.assigns.filters)
      |> Map.put("page", "1")

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:selected_ids, MapSet.new())
     |> load_data()}
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    filters = Forms.normalize_filters(%{"tab" => tab, "page" => "1"}, socket.assigns.filters)

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:selected_ids, MapSet.new())
     |> close_modal()
     |> load_data()}
  end

  def handle_event("page", %{"page" => page}, socket) do
    filters = Forms.normalize_filters(%{"page" => page}, socket.assigns.filters)

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:selected_ids, MapSet.new())
     |> load_data()}
  end

  def handle_event("toggle_select", %{"id" => id}, socket) do
    {:noreply, update(socket, :selected_ids, &toggle_id(&1, id))}
  end

  def handle_event("toggle_page_selection", _params, socket) do
    page_ids = Enum.map(socket.assigns.pagination.entries, & &1.id)
    selected_ids = socket.assigns.selected_ids

    next =
      if Enum.all?(page_ids, &MapSet.member?(selected_ids, &1)) do
        Enum.reduce(page_ids, selected_ids, &MapSet.delete(&2, &1))
      else
        Enum.reduce(page_ids, selected_ids, &MapSet.put(&2, &1))
      end

    {:noreply, assign(socket, :selected_ids, next)}
  end

  def handle_event("clear_selection", _params, socket) do
    {:noreply, assign(socket, :selected_ids, MapSet.new())}
  end

  def handle_event("view_user", %{"id" => id}, socket) do
    open_row_modal(socket, id, :view)
  end

  def handle_event("edit_user", %{"id" => id}, socket) do
    actor = socket.assigns.current_user

    with {:ok, end_user} <- Queries.get_scoped(id, actor),
         row <- row_for(socket, id) do
      {:noreply,
       assign(socket,
         modal: :edit,
         modal_row: row,
         edit_form: Forms.edit_form(end_user),
         editing_id: id
       )}
    else
      _error -> {:noreply, put_flash(socket, :error, "Could not load that end user.")}
    end
  end

  def handle_event("save_edit", %{"end_user" => params}, socket) do
    actor = socket.assigns.current_user

    with id when is_binary(id) <- socket.assigns[:editing_id],
         attrs <- Forms.attrs_for_update(params),
         {:ok, _end_user} <- Actions.run(actor, id, :update_profile, attrs) do
      {:noreply,
       socket
       |> put_flash(:info, "End user updated.")
       |> close_modal()
       |> load_data()}
    else
      _error -> {:noreply, put_flash(socket, :error, "Could not update that end user.")}
    end
  end

  def handle_event("request_action", %{"id" => id, "action" => action}, socket) do
    {:noreply, request_confirmation(socket, action, [id])}
  end

  def handle_event("request_bulk_action", %{"action" => action}, socket) do
    ids = MapSet.to_list(socket.assigns.selected_ids)

    if ids == [] do
      {:noreply, put_flash(socket, :error, "Select at least one end user first.")}
    else
      {:noreply, request_confirmation(socket, action, ids)}
    end
  end

  def handle_event("confirm_action", _params, socket) do
    %{action: action, ids: ids} = socket.assigns.confirmation
    actor = socket.assigns.current_user

    result =
      case ids do
        [id] -> single_result(Actions.run(actor, id, String.to_existing_atom(action)))
        ids -> Actions.bulk(actor, ids, String.to_existing_atom(action))
      end

    {:noreply,
     socket
     |> put_action_flash(action, result)
     |> assign(:selected_ids, MapSet.new())
     |> close_modal()
     |> load_data()}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, close_modal(socket)}
  end

  defp load_data(socket) do
    actor = socket.assigns.current_user
    pagination = Queries.list(actor, socket.assigns.filters)
    scoped_rows = Queries.scoped_end_users(actor)

    assign(socket,
      pagination: pagination,
      counts: %{
        users: Enum.count(scoped_rows, &(!&1.archived?)),
        archived: Enum.count(scoped_rows, & &1.archived?)
      },
      organizations: Queries.organizations_for(actor),
      platform_owner?: Queries.platform_owner?(actor),
      auth_methods: Forms.auth_methods()
    )
  end

  defp open_row_modal(socket, id, modal) do
    case row_for(socket, id) do
      nil ->
        {:noreply, put_flash(socket, :error, "Could not load that end user.")}

      row ->
        {:noreply, assign(socket, modal: modal, modal_row: row)}
    end
  end

  defp row_for(socket, id) do
    socket.assigns.current_user
    |> Queries.scoped_end_users()
    |> Enum.find(&(&1.id == id))
  end

  defp request_confirmation(socket, action, ids) do
    assign(socket,
      modal: :confirm,
      confirmation: confirmation(action, ids),
      modal_row: nil
    )
  end

  defp confirmation(action, ids) do
    count = length(ids)
    plural = if count == 1, do: "end user", else: "#{count} end users"

    base = %{
      action: action,
      ids: ids,
      danger?: action in ["ban", "archive", "delete"]
    }

    case action do
      "ban" ->
        Map.merge(base, %{
          title: "Ban #{plural}?",
          message: "Banned end users cannot sign in and their existing tokens will be revoked.",
          confirm_label: "Ban"
        })

      "unban" ->
        Map.merge(base, %{
          title: "Unban #{plural}?",
          message:
            "These end users will be allowed to sign in again if their application is active.",
          confirm_label: "Unban"
        })

      "archive" ->
        Map.merge(base, %{
          title: "Archive #{plural}?",
          message: "Archived end users cannot sign in and move to the Archived tab.",
          confirm_label: "Archive"
        })

      "restore" ->
        Map.merge(base, %{
          title: "Restore #{plural}?",
          message: "Restored end users move back to the Users tab.",
          confirm_label: "Restore"
        })

      "delete" ->
        Map.merge(base, %{
          title: "Permanently delete #{plural}?",
          message: "This hard-deletes archived end users and cannot be undone.",
          confirm_label: "Delete permanently"
        })
    end
  end

  defp put_action_flash(socket, action, %{ok: ok, error: []}) do
    put_flash(socket, :info, "#{action_label(action)} completed for #{length(ok)} end user(s).")
  end

  defp put_action_flash(socket, action, %{ok: ok, error: error}) do
    put_flash(
      socket,
      :error,
      "#{action_label(action)} completed for #{length(ok)} end user(s), failed for #{length(error)}."
    )
  end

  defp single_result({:ok, end_user}), do: %{ok: [end_user], error: []}
  defp single_result(_error), do: %{ok: [], error: [:failed]}

  defp action_label(action),
    do: action |> to_string() |> String.replace("_", " ") |> String.capitalize()

  defp close_modal(socket) do
    assign(socket,
      modal: nil,
      modal_row: nil,
      edit_form: nil,
      editing_id: nil,
      confirmation: nil
    )
  end

  defp toggle_id(selected_ids, id) do
    if MapSet.member?(selected_ids, id) do
      MapSet.delete(selected_ids, id)
    else
      MapSet.put(selected_ids, id)
    end
  end
end
