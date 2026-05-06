---
name: deep-research
description: Use this skill to conduct thorough, comprehensive web research, synthesize information, and produce high-quality, structured reports on complex topics.
---

# Deep Research Skill

This skill equips you with the methodology for conducting exhaustive, high-quality research. It is triggered when the user requests an in-depth investigation, a comprehensive report, or deep analysis of a specific topic.

## Core Methodology

When conducting deep research, follow these principles:
1. **Breadth and Depth:** Do not settle for the first Google search result. Use `google_web_search` to find multiple diverse sources (articles, documentation, academic papers, official repositories).
2. **Verification:** Cross-reference facts across at least two independent sources.
3. **Extraction:** Use `web_fetch` to deeply analyze the content of the most relevant URLs. Do not guess based on search snippets.
4. **Synthesis:** Combine your findings into a logically structured, highly readable Markdown report.

## The Research Workflow

For complex topics, always refer to [references/research_workflow.md](references/research_workflow.md) for the structured step-by-step procedure.

## Output Format
Your final output should always be a polished Markdown document containing:
- **Executive Summary**
- **Detailed Findings** (categorized logically)
- **Sources/Citations** (links to the original content)
