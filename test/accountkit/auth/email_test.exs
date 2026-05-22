defmodule Accountkit.Auth.EmailTest do
  use ExUnit.Case, async: true

  alias Accountkit.Auth.Email

  test "normalize/1 trims and lowercases" do
    assert Email.normalize("  Foo@Example.COM ") == "foo@example.com"
  end

end
