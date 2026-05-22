defmodule Accountkit.Accounts.PlatformOwnerBootstrapTest do
  use Accountkit.DataCase

  alias Accountkit.Accounts.{Authorization, PlatformOwnerBootstrap, User}

  setup do
    previous_email = Application.get_env(:accountkit, :platform_owner_email)

    on_exit(fn ->
      Application.put_env(:accountkit, :platform_owner_email, previous_email)
    end)
  end

  test "does nothing when no platform owner email is configured" do
    Application.delete_env(:accountkit, :platform_owner_email)

    assert {:error, :missing_email} = PlatformOwnerBootstrap.run()
  end

  test "does not create a platform owner for a missing user" do
    Application.put_env(:accountkit, :platform_owner_email, "missing@example.com")

    assert {:error, :user_not_found} = PlatformOwnerBootstrap.run()
  end

  test "grants platform owner to the configured existing user" do
    user = Ash.Seed.seed!(User, %{email: "owner@example.com", name: "Owner"})
    Application.put_env(:accountkit, :platform_owner_email, "owner@example.com")

    assert {:ok, :created} = PlatformOwnerBootstrap.run()
    assert Authorization.platform_owner?(user)
  end

  test "is idempotent for an existing platform owner" do
    user = Ash.Seed.seed!(User, %{email: "existing@example.com", name: "Owner"})
    Application.put_env(:accountkit, :platform_owner_email, "existing@example.com")

    assert {:ok, :created} = PlatformOwnerBootstrap.run()
    assert {:ok, :already_exists} = PlatformOwnerBootstrap.run()
    assert Authorization.platform_owner?(user)
  end

  test "grants platform owner to the authenticated configured user" do
    user = Ash.Seed.seed!(User, %{email: "AuthOwner@Example.COM", name: "Owner"})
    Application.put_env(:accountkit, :platform_owner_email, " authowner@example.com ")

    assert {:ok, :created} = PlatformOwnerBootstrap.grant_if_configured_user(user)
    assert Authorization.platform_owner?(user)
  end

  test "does not grant platform owner to a non-matching authenticated user" do
    user = Ash.Seed.seed!(User, %{email: "user@example.com", name: "User"})
    Application.put_env(:accountkit, :platform_owner_email, "owner@example.com")

    assert {:ok, :not_configured_owner} = PlatformOwnerBootstrap.grant_if_configured_user(user)
    refute Authorization.platform_owner?(user)
  end
end
