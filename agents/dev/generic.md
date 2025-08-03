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
> - using .env.project for project details like GH_TOKEN, GH_OWNER, GH_REPO, etc... (`This is for AI interaction only - separate from any project .env files`)

**Example .env.project file:**

```bash
# GitHub Configuration for AI Interaction
GH_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
GH_OWNER=your-username-or-organization
GH_REPO=repository-name
GH_PROJECT=123
```


## 2. Confirm Role and Context

> If you have questions about the role or context, please ask for clarification before proceeding.

Then

> Please summarize the role and context to ensure understanding.

## 2.1. General Communication Preferences

Set your default communication style for the entire session:

**Explanation Depth:**

- Prefer high-level overviews or detailed step-by-step explanations
- Request pseudocode, actual code, or conceptual descriptions

**Code Format Preferences:**

- Complete files, diffs only, or focused snippets
- Inline comments level (minimal, moderate, extensive)

**Interaction Style:**

- Ask for confirmation before each major step
- Provide alternatives when multiple approaches exist
- Explain reasoning behind technical decisions

*Note: These can be overridden in specific implementation steps as needed.*

## 3. Task Definition

### 3.0. Problem Description

- **State the specific issue**: Be precise about what's not working or what needs to be built
- **Provide error messages**: Include complete error logs, stack traces, or console outputs
- **Explain expected behavior**: Describe what should happen vs. what is actually happening
- **Include reproduction steps**: Detail how to reproduce the issue if applicable

### 3.1. Requirements Gathering

- **Functional requirements**: What the solution should accomplish
- **Non-functional requirements**: Performance, security, scalability considerations
- **Constraints**: Time, resource, or technical limitations
- **Dependencies**: External systems, APIs, or services that must be considered

### 3.2. Success Criteria

- **Acceptance criteria**: Define what constitutes a successful solution
- **Code quality standards**: Specify coding conventions, patterns, or best practices to follow
- **Documentation needs**: Indicate if comments, README updates, or other docs are required
- **Testing requirements**: Specify unit tests, integration tests, or manual testing needed

### 3.3. Task Source - Choose Your Approach

#### 3.3.1. Provide Task Using Github (if Task Already Defined)

> Use this (or a similar) command to read existing GitHub task details:

```bash
# For Github Repository tasks:

export $(cat .env.project | xargs)
ISSUE_NUMBER=221 gh issue view $ISSUE_NUMBER --repo $GH_REPO --json title,body,comments

# For Github Project tasks:

export $(cat .env.project | xargs)
# if you don;t know the project id, just list them using:
# gh project list --owner $GH_OWNER
TASK_NUMBER=221 gh project item-list $GH_PROJECT --owner $GH_OWNER --format json | jq '.items[] | select(.content.number == '$TASK_NUMBER') | {title: .content.title, body: .content.body}'
```

#### 3.3.2. Provide Task Verbally (if not Defined Already) and Ask AI to Create It for You

#### 3.3.2. Define Task Verbally and Create GitHub Issue

**Provide the task verbally:**

Provide task requirements to AI.

>Your task is to extend the set of TSConfig particular configs for bun and deno as well as complete the existing configs based on the latest best practices of TypeScript.
> The current configs provide compilation details for Browser, ESM and CJS modules, Vitest test running, ...

**Confirm Task:**

Make sure AI understood the task.

> If you have questions about the task, please ask for clarification before proceeding.

Answer all questions and repeat until no more questions, then

> Please summarize the task to ensure understanding.

**Create a Github Issue (and Attach it to a Github Project):**

Ask AI to create the task for you

> Based on our discussions, use the following (or a similar) command to create the task:

```bash
# Create Github Issue
export $(cat .env.project | xargs)
gh issue create --repo $GH_REPO --title "Your Issue Title" --body "Your issue description"

# Create Github Task and attach to Project
export $(cat .env.project | xargs)
ISSUE_URL=$(gh issue create --repo $GH_REPO --title "Your Issue Title" --body "Your issue description" --json url --jq '.url')
gh project item-add $GH_PROJECT --owner $GH_OWNER --url $ISSUE_URL

# Create using template example
export $(cat .env.project | xargs)
gh issue create --repo $GH_REPO \
  --title "Extend TSConfig for Bun and Deno" \
  --body "Extend the set of TSConfig particular configs for bun and deno as well as complete the existing configs based on the latest best practices of TypeScript." \
  --label "enhancement"
```

### 3.4. Code Context Sharing

If you have resources the AI needs to be aware of, share them with it.

- **Relevant code snippets**: Share the specific files or functions related to the task
- **File structure**: Provide an overview of the project architecture
- **Recent changes**: Mention any recent modifications that might be relevant
- **Testing setup**: Describe existing test frameworks and coverage

> Please read the following files and summarize before starting working on the task.

## 4. Implementation

### 4.1. Implementation Strategy

Ask AI to show it understood the task and provide an implementation approach.

> Please provide a short summary of how you would implement the request. Provide short code snippets (without providing the whole solution). If possible, use pseudo code not the requested programming language.

**Communication Preferences for this step:**

- Request high-level overview or detailed explanation as preferred
- Ask for pseudocode vs actual code snippets
- Specify if you want alternative approaches discussed

### 4.2. Test-Driven Development - Unit Tests

Ask AI to implement the unit tests first, following TDD principles.

> Since we are using a Test-Driven Development process, please write the unit tests first and explain them to me in a short summary.

**Communication Preferences for this step:**

- Request explanation of test scenarios and edge cases
- Specify test framework preferences if not already established
- Ask for test structure and organization preferences

### 4.3. Code Implementation

Ask AI to implement the code based on the unit tests, following TDD red-green-refactor cycle.

> Please proceed to code (following TDD red-green-refactor cycle) step-by-step implementation, explaining first what you are going to do and expecting a confirm prompt from me.

**Communication Preferences for this step:**

- Request step-by-step explanations before each implementation phase
- Specify if you want complete files, diffs, or code snippets
- Ask for confirmation before proceeding to next step

### 4.4. Testing and Validation

Run tests and validate the implementation works as expected.

> Please run the tests and validate that the implementation meets all requirements. If tests fail, explain what needs to be fixed.

**Communication Preferences for this step:**

- Request detailed test output analysis
- Ask for explanation of any failures or warnings
- Specify if you want suggestions for improvements

### 4.5. Debugging and Iteration

> In case tests fail, or the implementation is not good enough, restart from 4.1 again, providing small descriptions of what's not working properly.

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
