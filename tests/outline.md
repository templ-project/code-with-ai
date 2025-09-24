Outline Tests Inputs

## Generate Config Module HLD

```markdown
## Read `.github/prompts/outline.prompt.md` to understand how to act.

Write a HLD for a config module for services. HLD should

- be agnostic of technology
- be agnostic of cloud versus on-prem usage

Module should

- be able to load configuration from multiple sources (files/databases/vaults/config maps/side carts/etc)
- be able to support multiple environment levels (i.e. local to default to dev to stg to prod) (similar to config module in nodejs)
- should support hot reload and trigger hot reload on modules/applications/etc that use it (maybe event based?)

Feel free to bring other ideas from the field as well as ask any questions you see fit.
```

## Generate Logging Module HLD

```markdown
## Read `.github/prompts/outline.prompt.md` to understand how to act.

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
