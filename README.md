### envm .env manager

A simple cli tool to manage multiple .env for different environments:

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
