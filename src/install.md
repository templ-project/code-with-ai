

- Print the project logo using ASCII
```
   _____            _   _____
  / ____|          | | |_   _|
 | |     __      _ / \   | |
 | |     \ \ /\ / / / \  | |
 | |____  \ V  V / ____\_| |_
  \_____|  \_/\_/_/    \_____/

            C w A I
          Code with AI
```

- Ask what AI Client the user wants to install CwAI for:
   1. VSCode Copilot
   2. Copilot CLI
   3. Claude
   4. Gemini
- Read the answer in numerical form (1 to 5)
- If AI Client supports multiple install paths:
  - ask user (only if multiple choices) how he wants to install CwAI:
     1. Locally (in project)
     2. Globally
  - read the answer in numerical form (1 or 2)
- else, set the value yourself 1 for local, 2 for global
- If install path is local
  - ask user to provide the path to the project
  - read and validate the path exists
- Else, determine the global install path for the picked AI Client
- If the folders to install already exist in the provided path, ask how you should proceed
  1. Copy Over Existing
  2. Remove folders and copy again
- Read the answer in numerical form - 1 or 2
- Install the prompts from `.cwai/prompts` as required for each AI Client (keep in mind picked option in case .cwai already exists)
- Copy `.cwai` folder to the path for AI Client (keep in mind picked option in case .cwai already exists)
