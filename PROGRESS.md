# AccountKit Progress

## Current Status

AccountKit is freshly installed as a Phoenix/Ash application.

The project direction has been clarified:

- Build AccountKit in Elixir/Phoenix/Ash, not TypeScript.
- Use the old `_kit` TypeScript work only as historical context.
- Build a real SSO/account infrastructure app for the owner's other applications.
- Use the project as a path to become strong in the Elixir stack.
- Assistants should teach and guide first, and only write code when explicitly asked.

## Completed

- Created `GOAL.md` describing the AccountKit product vision and target stack.
- Created `GUIDANCE-GOAL.md` describing the teaching style, collaboration rules, TypeScript-to-Elixir explanations, and initial SSO direction.
- Confirmed the app includes Phoenix, LiveView, Ash, AshPostgres, AshAuthentication, AshAuthenticationPhoenix, AshAdmin, AshJsonApi, AshArchival, AshPaperTrail, Cinder, Swoosh, Req, Bandit, Tailwind, and related tooling.
- Removed/deferred money/accounting dependencies that blocked setup, because SSO does not need them yet.
- Ran `mix setup` successfully.

## Current Learning Focus

Start with understanding the fresh app before building SSO features.

The first goal is not to add features yet. The first goal is to understand the project skeleton well enough that future changes feel intentional.

## Next Steps

1. Run the app locally and make sure the Phoenix server boots.
2. Learn the top-level Phoenix project structure.
3. Learn the runtime supervision tree in `lib/accountkit/application.ex`.
4. Learn Mix basics through `mix.exs`, especially dependencies and aliases.
5. Learn Phoenix request flow: endpoint, router, controller/live route, template/component.
6. Learn where Ash is installed and what files/config it generated.
7. Identify the existing authentication resources, routes, and generated Ash Authentication pieces.
8. Inspect the production company SSO app as reference material.
9. Decide the first AccountKit SSO flow.
10. Build the first tiny vertical slice by hand.

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
- Created this progress tracker.
- Fixed initial dependency resolution by deferring `ash_money` and `ash_double_entry` (not needed for SSO).
- Ran `mix setup` successfully.
- Re-ran the Ash igniter installer, which generated Ash auth resources, routes, and the AshJsonApi router.
- Added `scalar_plug ~> 0.2.0` and mounted Scalar API docs at `/api/json/docs`.
- Scalar UI is now rendering in the browser.
- Next: understand the generated Ash auth files, then start building the first SSO resource.

