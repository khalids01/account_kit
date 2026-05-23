defmodule AccountkitWeb.Onboarding.OrganizationLive do
  use AccountkitWeb, :live_view

  alias Accountkit.Accounts.{Authorization, Organization, OrganizationMembership}
  alias Accountkit.Repo
  alias AccountkitWeb.Auth.OrganizationForm

  @impl true
  def mount(_params, _session, socket) do
    if Authorization.onboarding_required?(socket.assigns.current_user) do
      {:ok,
       socket
       |> assign(:page_title, "Set up organization")
       |> assign_form(%{})}
    else
      {:ok, push_navigate(socket, to: ~p"/dashboard")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.home flash={@flash} current_scope={%{user: @current_user}}>
      <section class="mx-auto flex min-h-[calc(100vh-4rem)] max-w-lg items-center px-6 py-16">
        <div class="w-full rounded-2xl border border-base-300 bg-base-100 p-8 shadow-sm">
          <div class="mb-8">
            <p class="text-sm font-semibold text-primary">Organization onboarding</p>
            <h1 class="mt-2 text-3xl font-bold tracking-tight">Create your organization</h1>
            <p class="mt-3 text-sm leading-6 text-base-content/70">
              This creates your first workspace and grants you organization admin access.
            </p>
          </div>

          <.form
            for={@form}
            id="organization-onboarding-form"
            phx-submit="save"
            phx-change="validate"
            class="space-y-5"
          >
            <.input
              field={@form[:name]}
              type="text"
              label="Organization name"
              required
              phx-debounce="blur"
              class="mt-2 w-full"
              placeholder="Acme Inc"
            />

            <.input
              field={@form[:text_logo]}
              type="text"
              label="Text logo"
              required
              maxlength="32"
              phx-debounce="blur"
              class="mt-2 w-full"
              placeholder="Acme"
            />

            <button type="submit" class="btn btn-primary w-full">
              Create organization
            </button>
          </.form>
        </div>
      </section>
    </Layouts.home>
    """
  end

  @impl true
  def handle_event("validate", %{"organization" => params}, socket) do
    {:noreply, assign_form(socket, params, :validate)}
  end

  def handle_event("save", %{"organization" => params}, socket) do
    changeset = OrganizationForm.changeset(params, action: :submit)

    if changeset.valid? do
      case create_organization_with_membership(socket.assigns.current_user, params) do
        {:ok, _organization} ->
          {:noreply,
           socket
           |> put_flash(:info, "Organization created.")
           |> push_navigate(to: ~p"/dashboard")}

        {:error, message} ->
          {:noreply, put_flash(socket, :error, message)}
      end
    else
      {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset, as: :organization))
  end

  defp assign_form(socket, params) when is_map(params) do
    assign_form(socket, params, nil)
  end

  defp assign_form(socket, params, action) when is_map(params) do
    assign_form(socket, OrganizationForm.changeset(params, action: action))
  end

  defp create_organization_with_membership(user, params) do
    Repo.transaction(fn ->
      with {:ok, organization} <- create_organization(user, params),
           {:ok, %OrganizationMembership{}} <- create_membership(user, organization) do
        organization
      else
        {:error, error} -> Repo.rollback(error)
      end
    end)
    |> case do
      {:ok, organization} -> {:ok, organization}
      {:error, error} -> {:error, error_message(error)}
    end
  end

  defp create_organization(user, params) do
    Organization
    |> Ash.Changeset.for_create(:create, params, actor: user)
    |> Ash.create()
  end

  defp create_membership(user, organization) do
    OrganizationMembership
    |> Ash.Changeset.for_create(
      :create,
      %{organization_id: organization.id, user_id: user.id, role: :org_admin},
      actor: user
    )
    |> Ash.create()
  end

  defp error_message(_error), do: "Could not create organization. Please check the form and try again."
end
