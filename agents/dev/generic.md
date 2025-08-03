# Developer Instructions for AI Interaction

## Overview

As a Developer working with AI, you need to provide clear, structured guidance to ensure the AI fully comprehends your task and can deliver accurate, actionable results. Follow these steps to maximize collaboration effectiveness.

## 1. Set the Role and the Context

> Role: You are a Senior Developer with
> - good knowledge of Design Patterns, Coding Principles and Clean Code
> - good knowledge of Test-Driven Development process
> Context: You are
> - working on an application/module that... (`Clearly state what type of application/system you're working on`)
> - using ... (`List programming languages, frameworks, libraries, and tools being used`)
> - using .env.project for project details like GH_TOKEN, GH_OWNER, GH_REPO, etc... (`If applicable, mention how environment variables are managed`)


## 2. Confirm Role and Context

> If you have questions about the role or context, please ask for clarification before proceeding.

Then

> Please summarize the role and context to ensure understanding.

## 3. Task Definition

- **State the specific issue**: Be precise about what's not working or what needs to be built
- **Provide error messages**: Include complete error logs, stack traces, or console outputs
- **Explain expected behavior**: Describe what should happen vs. what is actually happening
- **Include reproduction steps**: Detail how to reproduce the issue if applicable

- **Functional requirements**: What the solution should accomplish
- **Non-functional requirements**: Performance, security, scalability considerations
- **Constraints**: Time, resource, or technical limitations
- **Dependencies**: External systems, APIs, or services that must be considered

- **Acceptance criteria**: Define what constitutes a successful solution
- **Code quality standards**: Specify coding conventions, patterns, or best practices to follow
- **Documentation needs**: Indicate if comments, README updates, or other docs are required
- **Testing requirements**: Specify unit tests, integration tests, or manual testing needed

### 3.1. Provide task using Github

> Using the following command, read the task details

```bash
# For Github Repository tasks:

export $(cat .env | xargs)
ISSUE_NUMBER=221 gh issue view $ISSUE_NUMBER --repo $GH_REPO --json title,body,comments

# For Github Project tasks:

export $(cat .env | xargs)
# if you don;t know the project id, just list them using:
# gh project list --owner $GH_OWNER
TASK_NUMBER=221 gh project item-list $GH_PROJECT --owner $GH_OWNER --format json | jq '.items[] | select(.content.number == '$TASK_NUMBER') | {title: .content.title, body: .content.body}'
```

### 3.2. Provide Task verbally and ask AI to create the task for you

#### Provide the task verbally

>Your task is to extend the set of TSConfig particular configs for bun and deno as well as complete the existing configs based on the latest best practices of TypeScript.
> The current configs provide compilation details for Browser, ESM and CJS modules, Vitest test running, ...

#### Confirm Task

> If you have questions about the the task, please ask for clarification before proceeding.

Then

> Please summarize the task to ensure understanding.

#### Create a Github Issue (and Attach it to a Github Project)

> Based on our discussions, please create a task using the following command:

```bash
# Create Github Issue
export $(cat .env | xargs)
gh issue create --repo $GH_REPO --title "Your Issue Title" --body "Your issue description"

# Create Github Task
export $(cat .env | xargs)
ISSUE_URL=$(gh issue create --repo $GH_REPO --title "Your Issue Title" --body "Your issue description" --json url --jq '.url')
gh project item-add $GH_PROJECT --owner $GH_OWNER --url $ISSUE_URL

# Create using template
export $(cat .env | xargs)
gh issue create --repo $GH_REPO \
  --title "Extend TSConfig for Bun and Deno" \
  --body "Extend the set of TSConfig particular configs for bun and deno as well as complete the existing configs based on the latest best practices of TypeScript." \
  --label "enhancement"
```

### 3.3. Code Context Sharing

If you have resources the AI needs to be aware of, share them with it.

- **Relevant code snippets**: Share the specific files or functions related to the task
- **File structure**: Provide an overview of the project architecture
- **Recent changes**: Mention any recent modifications that might be relevant
- **Testing setup**: Describe existing test frameworks and coverage

> Please read the following files and summarize before starting working on the task.

### 3.4. Implementation Details

> Please provide a short summary of how you would implement the request. Provide short code snippets (without providing the whole solution). If possible, use pseudo code not the requested programming language.

### 3.5. Implementation of Unit Tests

> Since we are using a Test-Driven Development process, please write the unit tests and explain them to me in a short summary.


### 3.6. Implementation of Code

> Please proceed to code step-by-step implementation, explaining first what you are going to do and expecting a confirm prompt from me.

### 3.7. Debugging

> In case tests fail, or the implementation not being good enough, start from 3.1. again, by providing small descriptions on what's not working properly.

## Best Practices

### What to Do

- ✅ Provide complete error messages and logs
- ✅ Share relevant configuration and setup files
- ✅ Be specific about versions (Node.js 18.x, Python 3.11, etc.)
- ✅ Include examples of desired input/output
- ✅ Mention any patterns or conventions your team follows
- ✅ Ask for explanations of the solution approach

### What to Avoid

- ❌ Assume the AI knows your project structure
- ❌ Use vague terms like "it doesn't work"
- ❌ Skip mentioning important dependencies or integrations
- ❌ Forget to specify the target environment or platform
- ❌ Rush through the problem description

## Example Interaction Template

```markdown
**Context**: Working on a Node.js Express API with TypeScript, using PostgreSQL database
**Problem**: User authentication endpoint returning 500 error
**Error**: [paste complete error message]
**Expected**: Should return JWT token on successful login
**Files involved**: auth.controller.ts, user.model.ts, auth.middleware.ts
**Requirements**:
- Fix the authentication flow
- Maintain existing security practices
- Add appropriate error handling
- Include unit tests for the fix
**Environment**: Node.js 18.x, Express 4.x, TypeScript 5.x, PostgreSQL 14
```

## Validation Checklist

Before submitting your request, ensure you've covered:

- [ ] Clear problem statement
- [ ] Relevant technical context
- [ ] Expected outcome defined
- [ ] Error details provided (if applicable)
- [ ] Technology stack specified
- [ ] Code examples or file structure shared
- [ ] Requirements and constraints listed
- [ ] Quality standards mentioned
