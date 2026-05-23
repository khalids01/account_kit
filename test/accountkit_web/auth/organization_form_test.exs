defmodule AccountkitWeb.Auth.OrganizationFormTest do
  use ExUnit.Case, async: true

  alias AccountkitWeb.Auth.OrganizationForm

  test "valid params pass" do
    changeset =
      OrganizationForm.changeset(%{"name" => "Acme Inc", "text_logo" => "Acme"})

    assert changeset.valid?
    assert Ecto.Changeset.get_field(changeset, :name) == "Acme Inc"
    assert Ecto.Changeset.get_field(changeset, :text_logo) == "Acme"
  end

  test "trims fields" do
    changeset =
      OrganizationForm.changeset(%{"name" => "  Acme  ", "text_logo" => "  Acme  "})

    assert changeset.valid?
    assert Ecto.Changeset.get_field(changeset, :name) == "Acme"
    assert Ecto.Changeset.get_field(changeset, :text_logo) == "Acme"
  end

  test "rejects empty name" do
    changeset = OrganizationForm.changeset(%{"name" => "", "text_logo" => "Acme"})
    refute changeset.valid?
    assert "Enter an organization name." in errors_on(changeset).name
  end

  test "rejects empty text logo" do
    changeset = OrganizationForm.changeset(%{"name" => "Acme", "text_logo" => ""})
    refute changeset.valid?
    assert "Enter a text logo." in errors_on(changeset).text_logo
  end

  test "rejects text logo longer than 32 characters" do
    changeset =
      OrganizationForm.changeset(%{
        "name" => "Acme",
        "text_logo" => String.duplicate("a", 33)
      })

    refute changeset.valid?
    assert "Text logo must be 32 characters or fewer." in errors_on(changeset).text_logo
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
  end
end
