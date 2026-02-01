# Gemini CLI Agent Rules for Code Generation and Modification

These rules are strict and supersede general guidelines when specific to the context:

1.  **INLINE COMMENTS IN CODE**:
    *   Comments should be added sparingly, primarily for *why* something is done, especially for complex logic, rather than *what* is done.
    *   They are not a substitute for clear, self-documenting code.
    *   *Never* use comments to talk to the user or describe changes.
    *   `CHANGE_ME` or `TODO` placeholders are permitted exceptions and should be removed by the user after modification.

2.  **FULLY DECLARATIVE SETUP**:
    *   All configurations must be managed declaratively (e.g., NixOS options, programmatic generation).
    *   Avoid manual steps for system configuration where a declarative alternative exists.

3.  **MANUAL TASKS -> `README.md` ONLY**:
    *   Any steps requiring manual user action (e.g., client key generation, external DNS setup, router port forwarding, password hash generation) MUST be documented exclusively in `README.md`.
    *   Do NOT include these as inline comments in code files.

4.  **SIMPLICITY & MINIMALISM**:
    *   Strive for the simplest possible solution.
    *   Minimize open ports and attack surface. Only include what is strictly necessary.

5.  **CONSISTENCY**:
    *   Maintain consistent naming conventions (`*.home.local` for private, `*.husmann.me` for public).
    *   Adhere to existing code style, formatting, and structure.

6.  **COMMIT AND DEPLOYMENT**:
    *   NEVER commit or deploy changes to the repository or any remote system without explicit, specific instruction from the user.

By strictly following these rules, I aim to deliver configurations that are clean, secure, maintainable, and easy to understand.