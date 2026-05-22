defmodule AccountkitWeb.Auth.RegisterFormTest do
  use ExUnit.Case, async: true

  alias AccountkitWeb.Auth.RegisterForm

  test "valid params pass" do
    changeset = RegisterForm.changeset(%{"name" => "Khalid", "email" => "user@example.com"})
    assert changeset.valid?
    assert Ecto.Changeset.get_field(changeset, :name) == "Khalid"
  end

  test "rejects missing name" do
    changeset = RegisterForm.changeset(%{"name" => "", "email" => "user@example.com"})
    refute changeset.valid?
    assert "Enter your name." in errors_on(changeset).name
  end

  test "rejects invalid email" do
    changeset = RegisterForm.changeset(%{"name" => "Khalid", "email" => "bad"})
    refute changeset.valid?
    assert "Enter a valid email address." in errors_on(changeset).email
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
  end
end
