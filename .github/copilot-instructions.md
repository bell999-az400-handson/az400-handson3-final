# GitHub Copilot Instructions

This repository is for AZ-400 exam hands-on learning.

Rules:
- Follow Azure DevOps and GitHub best practices
- Prefer YAML pipelines over Classic
- Never put secrets in code
- Use Azure Key Vault for secrets
- Add comments explaining *why* not just *how*
- Assume the user is learning DevOps concepts
- Align answers with AZ-400 skills measured

## Using MCP Server for Azure DevOps

When getting work items using MCP Server for Azure DevOps, always try to use batch tools for updates instead of many individual single updates. For updates, try and update up to 200 updates in a single batch. When getting work items, once you get the list of IDs, use the tool `get_work_items_batch_by_ids` to get the work item details. By default, show fields ID, Type, Title, State. Show work item results in a rendered markdown table.