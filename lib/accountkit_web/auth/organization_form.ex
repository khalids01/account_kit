defmodule AccountkitWeb.Auth.OrganizationForm do
  @moduledoc """
  Schemaless changeset for organization onboarding.
  """
  import Ecto.Changeset

  @types %{name: :string, text_logo: :string}

  def changeset(params \\ %{}, opts \\ []) do
    {%{}, @types}
    |> cast(params, [:name, :text_logo])
    |> update_change(:name, &trim_field/1)
    |> update_change(:text_logo, &trim_field/1)
    |> validate_required([:name], message: "Enter an organization name.")
    |> validate_required([:text_logo], message: "Enter a text logo.")
    |> validate_length(:name, min: 1, max: 255, message: "Organization name is too long.")
    |> validate_length(:text_logo, max: 32, message: "Text logo must be 32 characters or fewer.")
    |> put_form_action(opts[:action])
  end

  defp put_form_action(changeset, nil), do: changeset
  defp put_form_action(changeset, action), do: %{changeset | action: action}

  defp trim_field(value) when is_binary(value), do: String.trim(value)
  defp trim_field(value), do: value
end
