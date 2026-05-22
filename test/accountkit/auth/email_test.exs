defmodule Accountkit.Auth.EmailTest do
  use ExUnit.Case, async: true

  alias Accountkit.Auth.Email

  test "normalize/1 trims and lowercases" do
    assert Email.normalize("  Foo@Example.COM ") == "foo@example.com"
  end

  test "valid?/1 accepts well-formed emails" do
    assert Email.valid?("user@example.com")
    assert Email.valid?("foo@bar.co")
  end

  test "valid?/1 rejects invalid emails" do
    refute Email.valid?("")
    refute Email.valid?("notanemail")
    refute Email.valid?("@example.com")
    refute Email.valid?("user@")
  end
end
