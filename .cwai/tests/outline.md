Outline Tests Inputs

## Generate Config Module HLD

```markdown
Read `.github/prompts/outline.prompt.md` to understand how to act.

Generic Multi Purpose Config Module: Write a HLD for a config module for services. HLD should

- be agnostic of technology
- be agnostic of cloud versus on-prem usage

Module should

- be able to load configuration from files
- be able to support multiple environment levels (i.e. local to default to dev to stg to prod) (similar to config module in nodejs)
- support hot reload
- on hot reload, trigger hot reload on dependant modules (probably event based)

Feel free to bring other ideas from the field as well as ask any questions you see fit.
```

### Generate Config Module LLD - 1

```markdown
Read `.github/prompts/outline.prompt.md` to understand how to act.

TypeScript Oriented Config Module LLD: Read the following HLD `./path/to/hld` and compose an LLD for it. Do not reinvent things. Use as many existing Node.js modules as possible.
```

### Generate Config Module LLD - 2

```markdown
Read `.github/prompts/outline.prompt.md` to understand how to act.

TypeScript Oriented Config Module LLD: Read the following HLD `./path/to/hld` and compose an LLD for it. Do not reinvent things. Use as many existing Node.js modules as possible.
Compose your LLD around `cosmiconfig` module. If you know a better one that fits the purpose, please mention that one. If you think writing a `from scratch` module would be better, explain your decision.
```

## Generate Logging Module HLD

```markdown
Read `.github/prompts/outline.prompt.md` to understand how to act.

Write a HLD for a logging module for services. HLD should

- be agnostic of technology
- gather information related to the service actions but also related to the service and the environment
- be agnostic of cloud versus on-prem usage

Module should

- have an complex tag capacity (yet easy to use),
- be configured from outside of the service (smth like side carts or config maps).
- configuration capacity for obfuscating key words in values, like password, emails, names, etc.
- have the capacity to log to tty, file, encrypted file (using AES+SSL).

Include information about

- logging levels
- possible configuration values and models

Feel free to bring other ideas from the field as well as ask any questions you see fit.
```
