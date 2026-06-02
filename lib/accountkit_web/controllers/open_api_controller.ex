defmodule AccountkitWeb.OpenApiController do
  use AccountkitWeb, :controller

  def show(conn, _params) do
    json(conn, spec())
  end

  defp spec do
    %{
      openapi: "3.0.3",
      info: %{
        title: "AccountKit API",
        version: "0.1.0",
        description:
          "Legacy-compatible Application SSO APIs. AccountKit control-plane authentication is intentionally separate from application end-user SSO authentication. See /docs/sso for the integration guide."
      },
      servers: [
        %{url: "/api", description: "AccountKit API"}
      ],
      tags: [
        %{
          name: "Application SSO Clients",
          description: "Validate SSO applications and read public client metadata."
        },
        %{
          name: "Application SSO Auth",
          description: "Authenticate end users for client applications."
        }
      ],
      paths: paths(),
      components: components()
    }
  end

  defp paths do
    %{
      "/auth/validate-client" => %{
        post: %{
          tags: ["Application SSO Clients"],
          summary: "Validate an SSO client token and redirect URL",
          operationId: "validateApplicationSsoClient",
          requestBody:
            json_body("ValidateClientRequest", "#/components/schemas/ValidateClientRequest"),
          responses: %{
            "200" => json_response("Client is valid", "#/components/schemas/SuccessResponse"),
            "400" =>
              json_response(
                "Missing or invalid redirect URL",
                "#/components/schemas/SimpleErrorResponse"
              ),
            "401" =>
              json_response(
                "Invalid or inactive client token",
                "#/components/schemas/SimpleErrorResponse"
              ),
            "403" =>
              json_response("Origin is not allowed", "#/components/schemas/SimpleErrorResponse")
          }
        },
        options: preflight_operation()
      },
      "/auth/client-info" => %{
        get: %{
          tags: ["Application SSO Clients"],
          summary: "Get public SSO client metadata",
          operationId: "getApplicationSsoClientInfo",
          parameters: [
            query_param("token", "Client token from the SSO application.", true)
          ],
          responses: %{
            "200" => json_response("Public client metadata", "#/components/schemas/PublicClient"),
            "400" =>
              json_response("Token is missing", "#/components/schemas/SimpleErrorResponse"),
            "401" =>
              json_response(
                "Invalid or inactive client token",
                "#/components/schemas/SimpleErrorResponse"
              )
          }
        }
      },
      "/rest/auth/login" => %{
        post: %{
          tags: ["Application SSO Auth"],
          summary: "Login an application end user with email and password",
          operationId: "loginApplicationEndUser",
          requestBody: json_body("LoginRequest", "#/components/schemas/LoginRequest"),
          responses: auth_responses()
        },
        options: preflight_operation()
      },
      "/rest/auth/register" => %{
        post: %{
          tags: ["Application SSO Auth"],
          summary: "Register an application end user with email and password",
          operationId: "registerApplicationEndUser",
          requestBody: json_body("RegisterRequest", "#/components/schemas/RegisterRequest"),
          responses: auth_responses()
        },
        options: preflight_operation()
      },
      "/rest/auth/me" => %{
        get: %{
          tags: ["Application SSO Auth"],
          summary: "Get the current application end user",
          operationId: "getCurrentApplicationEndUser",
          security: [%{bearerAuth: []}],
          responses: %{
            "200" =>
              json_response("Authenticated end-user profile", "#/components/schemas/UserResponse"),
            "401" =>
              json_response(
                "Missing, invalid, or non-end-user token",
                "#/components/schemas/ErrorResponse"
              )
          }
        },
        options: preflight_operation()
      },
      "/rest/auth/logout" => %{
        post: %{
          tags: ["Application SSO Auth"],
          summary: "Logout the current application end user token",
          operationId: "logoutApplicationEndUser",
          security: [%{bearerAuth: []}],
          responses: %{
            "200" =>
              json_response("Current token revoked", "#/components/schemas/SuccessResponse"),
            "401" =>
              json_response(
                "Missing, invalid, or non-end-user token",
                "#/components/schemas/ErrorResponse"
              )
          }
        },
        options: preflight_operation()
      }
    }
  end

  defp components do
    %{
      securitySchemes: %{
        bearerAuth: %{
          type: "http",
          scheme: "bearer",
          bearerFormat: "JWT",
          description:
            "Application end-user JWT from POST /api/rest/auth/login, POST /api/rest/auth/register, or the auth_token query parameter after SSO redirect."
        }
      },
      schemas: schemas()
    }
  end

  defp schemas do
    %{
      ValidateClientRequest: %{
        type: "object",
        required: ["token", "redirectUrl"],
        properties: %{
          token: string("Client token from the SSO application."),
          redirectUrl:
            string(
              "Callback URL configured on the SSO application.",
              "http://localhost:5173/callback"
            ),
          clientOrigin:
            string(
              "Optional browser origin to validate against allowed origins.",
              "http://localhost:5173"
            )
        }
      },
      LoginRequest: %{
        type: "object",
        required: ["email", "password", "token", "redirectUrl"],
        properties: %{
          email: string("End-user email address.", "end.user@example.com"),
          password: string("End-user password.", "password123"),
          token: string("Client token from the SSO application."),
          redirectUrl:
            string(
              "Callback URL configured on the SSO application.",
              "http://localhost:5173/callback"
            )
        }
      },
      RegisterRequest: %{
        type: "object",
        required: ["name", "email", "password", "token", "redirectUrl"],
        properties: %{
          name: string("End-user display name.", "End User"),
          email: string("End-user email address.", "end.user@example.com"),
          password: string("End-user password. Must be at least 8 characters.", "password123"),
          token: string("Client token from the SSO application."),
          redirectUrl:
            string(
              "Callback URL configured on the SSO application.",
              "http://localhost:5173/callback"
            )
        }
      },
      AuthSuccessResponse: %{
        type: "object",
        required: ["success", "token", "expires_in", "user", "client"],
        properties: %{
          success: %{type: "boolean", example: true},
          token: string("Application end-user JWT."),
          expires_in: %{
            type: "integer",
            description: "Remaining token lifetime in seconds.",
            example: 1_209_600
          },
          user: ref("#/components/schemas/EndUser"),
          client: ref("#/components/schemas/PublicClient")
        }
      },
      UserResponse: %{
        type: "object",
        required: ["success", "user"],
        properties: %{
          success: %{type: "boolean", example: true},
          user: ref("#/components/schemas/EndUser")
        }
      },
      SuccessResponse: %{
        type: "object",
        required: ["success"],
        properties: %{
          success: %{type: "boolean", example: true}
        }
      },
      SimpleErrorResponse: %{
        type: "object",
        required: ["error"],
        properties: %{
          error: string("Human-readable error message.", "Invalid client token")
        }
      },
      ErrorResponse: %{
        type: "object",
        required: ["success", "error", "code"],
        properties: %{
          success: %{type: "boolean", example: false},
          error: string("Human-readable error message.", "Invalid or expired token"),
          code: string("Machine-readable error code.", "INVALID_TOKEN")
        }
      },
      EndUser: %{
        type: "object",
        required: ["id", "name", "email"],
        properties: %{
          id: string("Application end-user id.", "0a0f85e5-5a10-4be6-b039-0a23b531df24"),
          name: string("End-user display name.", "End User"),
          email: string("End-user email address.", "end.user@example.com"),
          phone: nullable_string("Optional end-user phone number."),
          authMethods: %{
            type: "array",
            description: "Authentication methods used by this end user.",
            items: %{type: "string"},
            example: ["password"]
          }
        }
      },
      PublicClient: %{
        type: "object",
        required: ["id", "name"],
        properties: %{
          id: string("SSO application id.", "32d9a4e7-cba7-4ea8-a598-7ac67ff3c45e"),
          name: string("SSO application name.", "Example App"),
          logoUrl: nullable_string("Public logo URL."),
          passwordEnabled: %{type: "boolean", example: true},
          magicLinkEnabled: %{type: "boolean", example: false},
          googleEnabled: %{type: "boolean", example: false},
          googleClientId: nullable_string("Google OAuth client id."),
          facebookEnabled: %{type: "boolean", example: false},
          facebookAppId: nullable_string("Facebook app id."),
          linkedinEnabled: %{type: "boolean", example: false},
          linkedinClientId: nullable_string("LinkedIn client id.")
        }
      }
    }
  end

  defp auth_responses do
    %{
      "200" =>
        json_response("Authentication succeeded", "#/components/schemas/AuthSuccessResponse"),
      "400" =>
        json_response(
          "Invalid request, invalid email address, or password auth disabled",
          "#/components/schemas/ErrorResponse"
        ),
      "401" =>
        json_response("Invalid client token or credentials", "#/components/schemas/ErrorResponse")
    }
  end

  defp preflight_operation do
    %{
      tags: ["CORS"],
      summary: "CORS preflight",
      operationId: "corsPreflight",
      responses: %{
        "204" => %{description: "No content"}
      }
    }
  end

  defp json_body(name, schema_ref) do
    %{
      description: name,
      required: true,
      content: %{
        "application/json" => %{
          schema: ref(schema_ref)
        }
      }
    }
  end

  defp json_response(description, schema_ref) do
    %{
      description: description,
      content: %{
        "application/json" => %{
          schema: ref(schema_ref)
        }
      }
    }
  end

  defp query_param(name, description, required?) do
    %{
      name: name,
      in: "query",
      required: required?,
      description: description,
      schema: %{type: "string"}
    }
  end

  defp ref(schema_ref), do: %{"$ref" => schema_ref}

  defp string(description, example \\ nil) do
    schema = %{type: "string", description: description}

    if example do
      Map.put(schema, :example, example)
    else
      schema
    end
  end

  defp nullable_string(description) do
    %{
      type: "string",
      nullable: true,
      description: description
    }
  end
end
