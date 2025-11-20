# Security Policy

This repository is a minimal Oracle external procedure example intended for local/demo use only. It is **not** production-hardened.

- Do not expose the included XE container to the public internet.
- If you store secrets or sensitive data, add your own authentication/authorization, transport encryption, and key management.
- External libraries invoked from the UDF should be vetted and built from trusted sources.

## Reporting

If you believe you have found a vulnerability, please open a private issue or contact the maintainers directly rather than filing a public bug with details. Provide reproduction steps, environment details, and the potential impact.
