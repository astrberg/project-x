---
name: modify-cloud-function
description: Use when editing, debugging, or updating existing Python cloud functions.
---

# Modify Cloud Function

Use this skill to change logic, fix bugs, or update dependencies for existing Python cloud functions. Do not write tests or generate markdown files.

## When to use this skill

- Modifying code logic inside an existing function's main.py.
- Adding or updating packages in an existing function's requirements.txt.

## How to use it

### 1. Code Modifications

- No Comments: Do not add new comments. Remove any comments introduced during code generation.
- Import Structure: Keep imports strictly structured to match the existing file layout.
- No Markdowns: Do not alter or add markdown files.

### 2. Dependency Management

- Open functions/<function_name>/requirements.txt and manually append or update the required package versions. 
- Use the root uv environment strictly for local execution/linting context, not for function packaging.
