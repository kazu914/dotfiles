---
name: codex-collaboration
description: Use when the user asks to "codexと共同する", "codexと相談する", "consult with codex", "collaborate with codex", or explicitly requests Codex CLI-based analysis. For comprehensive codebase investigation, design consultation, or implementation advice via Codex. Use this skill instead of Web-Search tool.
---

# Codex Collaboration

This skill enables collaboration with Codex, an AI coding agent, for planning, design consultation, and comprehensive analysis. Codex serves as a consultant and partner for complex tasks.

## Purpose

Enable collaboration with Codex AI coding agent to leverage its capabilities for planning, design consultation, implementation advice, and comprehensive codebase analysis.

## Execution

When this skill is triggered, verify the current Codex CLI usage first, then execute the appropriate command:

### Step 1: Verify Codex CLI

Check current version and help:

```bash
codex --version
codex --help
```

This ensures compatibility with the current Codex installation and prevents version-dependent issues.

### Step 2: Execute Codex

Execute the Codex CLI to consult with the AI coding agent:

```bash
codex exec "[PROMPT]"
```

## Usage Examples

### Example 1: Web Search Request

When web search is needed for current information:

```bash
codex e --enable web_search_request "Search for the latest best practices for React state management in 2026 and summarize the key approaches"
```

### Example 2: Comprehensive Codebase Investigation

When analyzing the entire codebase:

```bash
codex exec --cd /path/to/project "Analyze this entire codebase structure. Identify:
1. Main architectural patterns used
2. Key modules and their responsibilities
3. Potential code smells or technical debt
4. Areas for improvement
Provide a comprehensive summary with specific file references."
```

### Example 3: Code Change Feedback

When seeking feedback on current code changes:

```bash
codex exec "I just made the following code changes:

[Describe what you changed - e.g., 'Added async/await to the data fetching function' or paste the diff]

My thoughts/concerns:
- [Share your thoughts - e.g., 'I\\'m worried this might introduce race conditions' or 'I think this improves readability but not sure about performance']

Please provide:
1. Your assessment of these changes
2. Any potential issues or concerns I should be aware of
3. Latest best practices for this type of implementation
4. Recommendations for improvements if applicable

Research current best practices if needed to give informed advice."
```

### Example 4: Design Consultation

For architecture and design decisions:

```bash
codex exec "Review this implementation approach for [feature]. Consider:
- Scalability implications
- Security considerations
- Performance characteristics
- Maintainability concerns
Provide recommendations and alternative approaches if applicable."
```

## Common Options (Verify with --help)

Options may vary by version. Always check `codex --help` for current options:

- `--cd <DIR>` - Set working directory (use `--cd`, not `-C`)

## Best Practices

- Verify first: Always check `codex --help` before using options to ensure compatibility
- Proactively invoke Codex for comprehensive analysis or external validation
- Use `web_search_request` feature when web search capability is needed (verify if live search is enabled)
- Specify clear, structured prompts for best results
- Leverage Codex for architecture planning and design consultation
