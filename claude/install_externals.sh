#!/bin/bash
skills=(
  "frontend-design@claude-plugins-official"
  "context7@claude-plugins-official"
)

for skill in "${skills[@]}"; do
  claude plugin install $skill
done

# codex
claude plugin marketplace add openai/codex-plugin-cc
claude plugin install codex@openai-codex --scope user
