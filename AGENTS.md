# Development Agents – Guidelines

## Context7 Usage
- Always route code generation, setup, configuration, or library/API documentation requests through the Context7 MCP tools.
- Resolve the library ID first with `resolve-library-id`, then fetch focused docs via `get-library-docs` without waiting for an explicit prompt.

## Mandatory Testing Workflow
- After every code change (feature, bug fix, refactor), run the full Flutter validation suite to protect stability.
- Execute the commands below in order and address any failures immediately.

```bash
flutter pub get
flutter analyze
flutter test
```
