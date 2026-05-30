defmodule Accountkit.Accounts.UserManagementTest do
  use Accountkit.DataCase

  alias Accountkit.Accounts.{PlatformRole, User}

  test "platform owners can ban and unban another user" do
    owner = user!("owner-ban@example.com")
    target = user!("target-ban@example.com")
    Ash.Seed.seed!(PlatformRole, %{user_id: owner.id, role: :platform_owner})

    assert {:ok, banned_user} = update_user(target, :ban, owner)
    assert %DateTime{} = banned_user.banned_at

    assert {:ok, unbanned_user} = update_user(banned_user, :unban, owner)
    assert is_nil(unbanned_user.banned_at)
  end

  test "platform owners can archive and restore another user" do
    owner = user!("owner-archive@example.com")
    target = user!("target-archive@example.com")
    Ash.Seed.seed!(PlatformRole, %{user_id: owner.id, role: :platform_owner})

    assert {:ok, archived_user} = update_user(target, :archive, owner)
    assert %DateTime{} = archived_user.archived_at

    assert {:ok, restored_user} = update_user(archived_user, :restore, owner)
    assert is_nil(restored_user.archived_at)
  end

  test "non platform owners cannot manage users" do
    actor = user!("plain-manager@example.com")
    target = user!("plain-target@example.com")

    assert {:error, %Ash.Error.Forbidden{}} = update_user(target, :ban, actor)
    assert {:error, %Ash.Error.Forbidden{}} = update_user(target, :archive, actor)
  end

  test "platform owners cannot ban or archive themselves" do
    owner = user!("self-owner@example.com")
    Ash.Seed.seed!(PlatformRole, %{user_id: owner.id, role: :platform_owner})

    assert {:error, %Ash.Error.Forbidden{}} = update_user(owner, :ban, owner)
    assert {:error, %Ash.Error.Forbidden{}} = update_user(owner, :archive, owner)
  end

  defp update_user(user, action, actor) do
    user
    |> Ash.Changeset.for_update(action, %{}, actor: actor)
    |> Ash.update()
  end

  defp user!(email) do
    Ash.Seed.seed!(User, %{email: email, name: "Test User"})
  end
end
