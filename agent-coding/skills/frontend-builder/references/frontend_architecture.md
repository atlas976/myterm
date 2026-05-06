# Frontend Architectural Patterns

## State Management
- **Local State:** Use `useState` or `useReducer` for state that is only relevant to a single component or its immediate children.
- **Global State:** For prototypes and small apps, prefer React Context to avoid the overhead of Redux or Zustand unless requested.

## Component Hierarchy
- **Container / Presentational Pattern:** 
  - *Containers (Pages):* Handle data fetching, state management, and pass data down.
  - *Presentational (Components):* Pure UI components that receive data via props and emit events via callbacks.

## Styling Guidelines (Vanilla CSS)
- Use CSS variables (`var(--primary-color)`) for theming.
- Implement responsive design primarily using CSS Grid and Flexbox.
- Ensure interactive elements (buttons, links) have clear `:hover` and `:active` states.
- Use a CSS reset or normalize at the top of your main stylesheet.