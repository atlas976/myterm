# The Deep Research Workflow

When executing a deep research task, follow this exact sequence:

## Phase 1: Planning
1. **Deconstruct the Prompt:** Identify the core question, required constraints, and the target audience for the final report.
2. **Formulate Queries:** Generate 3-5 distinct search queries designed to capture different angles of the topic (e.g., technical, historical, practical).

## Phase 2: Execution
1. **Initial Sweep:** Run your search queries using `google_web_search` in parallel to gather a broad set of URLs.
2. **Deep Dive:** Select the 3-5 most authoritative URLs and use `web_fetch` to extract detailed information. If a page is too dense, use specific prompt instructions within `web_fetch` to extract exactly what you need.
3. **Iterative Refinement:** If the initial results leave gaps, formulate new, highly specific search queries to fill them.

## Phase 3: Synthesis
1. **Outline:** Create a logical structure for the report before writing.
2. **Drafting:** Write the report using clear, objective language. Avoid conversational filler.
3. **Citation:** Ensure every major claim is backed by a specific URL gathered during Phase 2.