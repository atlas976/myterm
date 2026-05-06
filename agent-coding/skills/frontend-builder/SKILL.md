---
name: frontend-builder
description: Use this skill when asked to build, scaffold, or design a frontend web application, UI component, dashboard, or website.
---

# Frontend Builder Skill

This skill provides expert guidance for scaffolding and implementing modern, aesthetically pleasing, and highly functional frontend applications.

## Core Directives
1. **Scaffolding:** When starting a new project, use modern, fast build tools. Prefer `Vite` for React/Vanilla JS over older tools like Create React App. Use non-interactive flags (e.g., `npm create vite@latest my-app -- --template react-ts`) to avoid hanging the terminal.
2. **Styling:** Unless the user specifically requests a framework like Tailwind, use Vanilla CSS or CSS Modules. Ensure the UI feels modern: use flexbox/grid for layouts, maintain consistent padding/margins, and use a polished color palette.
3. **Component Structure:** Write modular, reusable components. Keep state management as close to where it's needed as possible.

## Architectural Best Practices
Before implementing complex routing or state, review [references/frontend_architecture.md](references/frontend_architecture.md) for established patterns.

## Execution
- Always ensure `package.json` is updated and `npm install` is run successfully.
- Verify the build compiles without errors.
- Do not leave placeholder UI (like the default Vite counter) in the final product unless it's a bare scaffold. Provide an actual functioning prototype related to the user's request.
