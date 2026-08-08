---
name: update-from-openapi
description: Use this skill when you need to align Spring Boot Controller endpoints, error handling, and API documentation with an OpenAPI specification, including strict header and field matching, response body conformity, OpenAPI annotation updates, error schema enforcement, Swagger UI validation, and updating .http files for endpoint testing or contract reviews.
---

# Guidelines and Standards

### When to use this skill
- When aligning Spring Boot Controller endpoints to an OpenAPI specification
- When creating Spring Boot Controller endpoints to an OpenAPI specfication
- To ensure request/response headers and bodies match the OpenAPI contract
- When updating error handling to conform to OpenAPI error schemas
- For adding or correcting OpenAPI annotations on controller methods
- When validating or updating API documentation in Swagger UI
- To update or create .http files for endpoint testing as per OpenAPI spec
- During API contract reviews or refactoring for OpenAPI compliance

### Instructions
If the user doesn't provide a path or endpoint to analze in the OpenAPI spec provided to you then prompt the user to provide one or more endpoints.

Once the endpoint(s) are specified, analyze the the OpenAPI specification in context and completely understand it for the endpoint(s) provided. Now if the controller endpoint exists, align the controller endpoint according to the OpenAPI spec.

If the controller endpoint does not exist, create the controller endpoint according to the OpenAPI spec.

Follow these instructions.

- **Headers and Fields:**
  - Only accept and return headers that are explicitly defined in the OpenAPI specification.  
  - Remove any request or response headers and fields that are not present in the OpenAPI spec.
  - Ensure all required request headers are present as `@RequestHeader` parameters.
  - Ensure all required response headers are present in the `ResponseEntity`.

- **Response Body:**
  - Ensure the response body matches the OpenAPI schema exactly (e.g., binary PDF or JSON as specified).
  - Do not include any extra fields or structures not defined in the OpenAPI spec.

- **Error Handling:**
  - If an error handling framework exists, update error handling (e.g., `GlobalExceptionHandler`) to:
    - Return error responses that match the OpenAPI error schema (e.g., `StandardErrorResponse`).
    - Include only the required error response headers (e.g., `X-Timestamp`, `X-Trace-Id`).
    - Remove any error fields or headers not present in the OpenAPI spec.
    - Hardcode or generate values for required fields if not available.

- **OpenAPI Annotations:**
  - Update OpenAPI annotations (`@Operation`, `@ApiResponses`, `@ApiResponse`, `@Header`, `@Schema`, `@Content`, etc.) on the controller method to:
    - Explicitly document all response headers for each status code.
    - Reference the correct response body schema for success and error cases.
    - Add `examples` for error responses if present in the OpenAPI spec.
    - Remove annotation references to headers or fields not present in the OpenAPI spec.
    - Ensure to use all the following imports and implement them:
      - `io.swagger.v3.oas.annotations.parameters.RequestBody`
      - `io.swagger.v3.oas.annotations.media.ExampleObject` - Ensure that the examples in OpenAPI spec are annotated.
      - `io.swagger.v3.oas.annotations.media.Schema` - Ensure that schemas are referenced as they are in the OpenAPI spec

- **Documentation and Validation:**
  - Ensure the endpoint is documented as accurately as possible and mirrors the example OpenAPI specification.
  - Validate the Swagger UI to confirm the endpoint documentation matches the OpenAPI specification.

- **.http Files:**
  - Update or create `.http` files for endpoint testing, ensuring request and response structure matches the new OpenAPI specification.
  - Remove any references to headers or fields not present in the OpenAPI spec from the `.http` files.

- **Tests:**
  - Do not modify or update tests for now.
