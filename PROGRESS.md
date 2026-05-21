# AccountKit Progress

## Current Status

Basic UI shell is working. The app boots, renders a homepage with a layout, header with user menu and theme toggle, and the Scalar API docs page. The next focus is building the dashboard LiveView and then moving into SSO.

## Completed

- Created `GOAL.md`, `GUIDANCE-GOAL.md`, and `PROGRESS.md` to track direction and learning goals.
- Fixed dependency conflict by deferring `ash_money` and `ash_double_entry`.
- Ran `mix setup` successfully.
- Re-ran Ash igniter installer — generated `Accounts` domain, `User`, `Token`, `ApiKey` resources, auth routes, and `AshJsonApiRouter`.
- Added `scalar_plug ~> 0.2.0` and mounted Scalar API docs at `/api/json/docs`.
- Learned Phoenix layout system: `root.html.heex`, `layouts.ex`, `core_components.ex`, how assigns flow.
- Learned HEEx concepts: sigils (`~H`, `~p`), named slots (`<:slot_name>`), attrs as props, arity rules.
- Learned why `core_components.ex` cannot use `use AccountkitWeb, :html` (circular dependency).
- Learned Phoenix module system: no auto-imports, explicit imports, arity always 1 for components.
- Created `lib/accountkit_web/components/ui_components.ex` for app-specific components (user_menu, theme_toggle).
- Created `lib/accountkit_web/components/sections/headers.ex` for page section components.
- Homepage renders with working layout, header, user menu (shows login button when not authenticated), and theme toggle.
- Confirmed `ash_admin` works at `/admin`.

## Current Learning Focus

Building the dashboard LiveView and understanding how LiveViews differ from controller-rendered templates.

## Next Steps

1. Build `DashboardLive` at `/dashboard` — first real LiveView written by hand.
2. Add `on_mount` auth guard so only logged-in users can access dashboard.
3. Build dashboard layout with sidebar (Settings, Profile, Projects).
4. Convert homepage from controller-rendered to LiveView.
5. Inspect the production company SSO app as reference for the first SSO flow.
6. Design and build the first SSO vertical slice.

## First Vertical Slice Target

The first real product slice should be intentionally small:

- Register or seed one trusted client app.
- Let a user sign in to AccountKit.
- Redirect back to the client app with a short-lived code or token.
- Let the client app exchange/verify that result.
- Show the current user in the client app.

Do not add billing, tenants, API keys, admin dashboards, or audit logs until the basic SSO loop is understood.

## Concepts To Learn First

- `defmodule`, `def`, arity, aliases, imports, and module attributes.
- Pattern matching, tuples, atoms, maps, structs, and pipes.
- `mix.exs`, dependencies, aliases, environments, and config.
- Phoenix endpoint, router, plugs, controllers, LiveView, and layouts.
- Ecto repository and migrations, even when Ash owns most domain modeling.
- Ash resources, domains, actions, attributes, relationships, validations, changes, and policies.
- Ash Authentication users, tokens, routes, plugs, and Phoenix integration.

## Open Questions

- Where is the production company SSO code located in this workspace?
- Which app should AccountKit integrate with first?
- Should the first SSO version be a simple internal trusted-app flow, OAuth2/OIDC-like, or simple first and OIDC-like later?
- What user fields must be shared across all apps?
- Should tokens be signed JWTs, opaque database tokens, or both?
- Should tenants/accounts exist from day one or after the basic SSO flow works?
- How should logout across apps work?

## Session Log

### 2026-05-21

- Confirmed the project is freshly installed.
- Created progress tracker, guidance goal, and goal files.
- Fixed `ash_money`/`ash_double_entry` dependency conflict.
- Ran `mix setup` successfully.
- Re-ran Ash igniter — generated auth resources, routes, AshJsonApiRouter.
- Added and wired `scalar_plug` for Scalar API docs at `/api/json/docs`.
- Learned Phoenix layout system, HEEx syntax, sigils, slots, attrs, arity.
- Learned module import rules, circular dependency constraints, `~p` verified routes.
- Built `ui_components.ex` (user_menu, theme_toggle) and `sections/headers.ex`.
- Fixed nil crash on `current_scope` access when user is not logged in.
- Homepage and header now render correctly in the browser.
- Ash admin confirmed working at `/admin`.
- Next session: build `DashboardLive` and first real LiveView.

