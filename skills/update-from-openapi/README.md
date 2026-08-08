
# update-from-openapi

## Summary
The update-from-openapi skill helps align Spring Boot Controller endpoints, error handling, and API documentation with an OpenAPI specification. It ensures strict contract compliance for headers, fields, response bodies, and OpenAPI annotations, and supports updating .http files for endpoint testing and contract reviews.

## Detail

This skill is used when you need to create or update Spring Boot Controller endpoints to match an OpenAPI spec. It enforces exact header and field matching, response body conformity, and error schema enforcement as defined in the OpenAPI contract. The skill guides you to update or add OpenAPI annotations, ensure Swagger UI documentation is accurate, and update .http files for endpoint testing. It also covers updating error handling to match OpenAPI error schemas and removing any undocumented headers or fields. The skill prompts for endpoint details if not provided and ensures all changes strictly follow the OpenAPI specification.

## Possible Improvements

- Automate endpoint extraction and mapping from OpenAPI specs
- Add support for generating or updating tests based on OpenAPI contracts

## Example Activation Prompts
- Align this controller with the provided OpenAPI spec
- Update error handling and documentation to match the OpenAPI contract
