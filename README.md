# ExeCop

ExeCop is a checker that check commands and environment variables before execute command.

## Install

```zsh
source /path/to/execop.zsh
```

## Usage

Put `.execop` file to `/path/to/dir` like `.htaccess`.

`.execop` file looks like following

```
deny when command_match destroy
confirm when command_match rm
confirm when env_eq AWS_PROFILE=production
```

## `.execop` file format

```
deny when command_match destroy
```

```
[action] when [matcher] [command or environment value]
```
