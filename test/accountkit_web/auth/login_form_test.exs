defmodule AccountkitWeb.Auth.LoginFormTest do
  use ExUnit.Case, async: true

  alias AccountkitWeb.Auth.LoginForm

  test "valid email passes" do
    changeset = LoginForm.changeset(%{"email" => "user@example.com"})
    assert changeset.valid?
    assert Ecto.Changeset.get_field(changeset, :email) == "user@example.com"
  end

  test "normalizes email" do
    changeset = LoginForm.changeset(%{"email" => "  User@Example.COM "})
    assert changeset.valid?
    assert Ecto.Changeset.get_field(changeset, :email) == "user@example.com"
  end

  test "rejects empty email" do
    changeset = LoginForm.changeset(%{"email" => ""})
    refute changeset.valid?
    assert "Enter your email address." in errors_on(changeset).email
  end

  test "rejects invalid email format" do
    changeset = LoginForm.changeset(%{"email" => "notanemail"})
    refute changeset.valid?
    assert "Enter a valid email address." in errors_on(changeset).email
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
  end
end
