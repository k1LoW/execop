# ExeCop

ExeCop is a checker that check commands and environment variables before execute command.

![demo](demo.gif)

## Install

If you use Zsh, add the following line to your .zshrc

```zsh
. /path/to/execop.zsh
```

If you use Bash, add the following line to your .bashrc

```bash
. /path/to/execop.bash
```

## Usage

Put `.execop` file to `/path/to/dir` like `.htaccess`.

`.execop` file looks like following code

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

| action |  |
| --- | --- |
| `deny` | deny command if macther match |
| `confirm` | insert `yes/no` confirm if macther match |

| matcher |  |
| --- | --- |
| `command_match` | command ~= value |
| `command_not_match` | ! command ~= value |
| `command_eq` | command = value |
| `command_not_eq` | command != value |
| `env_eq` | $SOMEENV = value |
| `env_not_eq` | $SOMEENV != value |

