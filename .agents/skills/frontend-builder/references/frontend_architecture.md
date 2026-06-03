# Frontend Architectural Patterns

## State Management

- Use local state for state that belongs to a single component or nearby children.
- Use React Context for small app-wide state.
- Avoid Redux, Zustand, or similar libraries unless the repo already uses them or the request needs them.

## Component Hierarchy

- Use page/container components for data loading, workflow state, and orchestration.
- Use presentational components for reusable UI that receives props and emits callbacks.

## Styling

- Use CSS variables for theme tokens.
- Use Grid and Flexbox for responsive layouts.
- Provide hover, active, disabled, loading, and empty states for interactive surfaces.
- Keep text inside its containers across mobile and desktop viewports.
