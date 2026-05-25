---
name: create-cloud-function
description: Use when creating a brand new Python cloud function in the repository.
---

# Create Cloud Function

Use this skill when you need to initialize a new Python cloud function from scratch. Do not write any tests or generate markdown files.

## When to use this skill

- Creating a new directory under functions/.
- Setting up the initial main.py and requirements.txt files for a new endpoint.

## How to use it

### 1. File Structure Creation
Create the folder and necessary files using this exact layout:

functions/
└── <new_function_name>/
    ├── main.py
    └── requirements.txt

### 2. Boilerplate Templates

Use the following boilerplate structures. Do not include any comments or docstrings in the final codebase files.

#### HTTP Triggers
```python
import logging
import os

import functions_framework

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


@functions_framework.http
def <function_name>(request):
    return "", 200
```

#### Event (CloudEvent) Triggers
```python
import logging
import os

import functions_framework
from cloudevents.http import CloudEvent

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


@functions_framework.cloud_event
def <function_name>(cloud_event: CloudEvent):
    return
```

### 3. Implementation Rules

- No Comments: Do not write any comments inside main.py or requirements.txt.
- Import Structure: Match the exact import grouping and styling shown in the boilerplates.
- No Markdowns: Do not generate documentation or README files.
- Dependencies: Add only the required packages directly to the new requirements.txt. Do not use root uv to add dependencies to the function folder.
