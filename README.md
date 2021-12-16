## envm

### A .env manager

### Overview

A simple cli tool to manage multiple .env for different environments. It is written in crystal (compiled ruby) See: [The Crystal Programming Language](https://crystal-lang.org/)

```
Manage .env versions
    -v, --version                    Show version
    -h, --help                       Show help
    list                             List .env versions
    current                          Show current .env version
    use                              Use a .env version
```

To list envs in current working directory:

```
envm list
```

Which would show:

```
dev
pre-prod
stage
```

Given the following files:

```
.env
.env.dev
.env.pre-prod
.env.stage
.env~
```

To use a given env:

```
envm use dev
```

Which would show:

```
using dev
```

Note the `envm use` has the following side effects:

1. The current .env will be backed up into .env~ (Useful if you made manual changes to .env)
2. The given env will be copied into .env (overwriting it)
3. A special envar is prepended into .env `ENVM=dev` (used by `envm current`)

To show which env is current:

```
envm current
```

Which would show:

```
dev
```

### Partials

Sometimes it is useful to spit up a env into parts. Consider the follow env files:

```
.env.dev
.env.dev.personal-secrets
.env.dev.shared-secrets
.env.dev.overrides
```

These would all be combined using a single `envm use` command:

```
envm use dev
```

This would combine all of these partials into a single .env

`.env.dev` would contain the non-secret base (or common) envars.
`.env.dev.personal-secrets` would contain personal secrets (local dev mysql user/password)
`.env.dev.shard-secrets` would contain shared secrets (shared certs, keys, etc.)
`.env.dev.overrides` would contain other overrides

The base `.env.dev` is loaded first, then each partial `.env.dev.*` is loaded in order and its contents is merged and superceeds current content. If you need to control the order that partials are applied, you can force order via naming:

```
.env.dev
.env.dev.1-shared-secrets
.env.dev.2-personal-secrets
.env.dev.3-overrides
```
