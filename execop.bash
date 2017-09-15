-execop-preexec () {
    local rules=''
    rules=$(-execop-gather-dotfiles)
    local cmd="${1}"
    if [ "${rules}" = '' ]; then
        return
    fi
    local IFS=$'\n'
    local rules=($rules)
    for rule in "${rules[@]}"; do
        local IFS=$' '
        local arr=($rule)
        local action=${arr[0]}
        local matcher=${arr[2]}
        local cmd_or_env=''
        cmd_or_env="$(IFS=,; echo "${arr[@]:3}")"
        if [ -z "${cmd_or_env}" ]; then
            continue
        fi
        if [ "${arr[1]}" != "when" ]; then
            continue
        fi

        ## command_match
        if [ $matcher = "command_match" ]; then
            if [[ $cmd =~ $cmd_or_env ]]; then
                if [ $action = "deny" ]; then
                    -execop-deny-command "${cmd}"
                fi
                if [ $action = "confirm" ]; then
                    -execop-confirm-command "${cmd}"
                fi
            fi
        fi

        ## command_not_match
        if [ $matcher = "command_not_match" ]; then
            if [[ $cmd =~ $cmd_or_env ]]; then
                :
            else
                if [ $action = "deny" ]; then
                    -execop-deny-command "${cmd}"
                fi
                if [ $action = "confirm" ]; then
                    -execop-confirm-command "${cmd}"
                fi
            fi
        fi

        ## command_eq
        if [ $matcher = "command_eq" ]; then
            if [ $cmd = $cmd_or_env ]; then
                if [ $action = "deny" ]; then
                    -execop-deny-command "${cmd}"
                fi
                if [ $action = "confirm" ]; then
                    -execop-confirm-command "${cmd}"
                fi
            fi
        fi

        ## command_not_eq
        if [ $matcher = "command_not_eq" ]; then
            if [ $cmd != $cmd_or_env ]; then
                if [ $action = "deny" ]; then
                    -execop-deny-command "${cmd}"
                fi
                if [ $action = "confirm" ]; then
                    -execop-confirm-command "${cmd}"
                fi
            fi
        fi

        ## env_eq
        if [ $matcher = "env_eq" ]; then
            local IFS="=";
            local splitted=($cmd_or_env);
            local envname=${splitted[0]}
            local envvalue=${splitted[1]}
            local actual=''
            actual="$(eval echo '$'$envname)"
            if [ $actual ] && [ $envvalue = $actual ]; then
                if [ $action = "deny" ]; then
                    -execop-deny-command "${cmd}"
                fi
                if [ $action = "confirm" ]; then
                    -execop-confirm-command "${cmd}"
                fi
            fi
        fi

        ## env_not_eq
        if [ $matcher = "env_not_eq" ]; then
            local IFS="=";
            local splitted=($cmd_or_env);
            local envname=${splitted[0]}
            local envvalue=${splitted[1]}
            local actual=''
            actual="$(eval echo '$'$envname)"
            if [ $actual ] && [ $envvalue != $actual ]; then
                if [ $action = "deny" ]; then
                    -execop-deny-command "${cmd}"
                fi
                if [ $action = "confirm" ]; then
                    -execop-confirm-command "${cmd}"
                fi
            fi
        fi
    done
}

-execop-gather-dotfiles() {
    local dotfile='.execop'
    local lines=''
    while :
    do
        if [ "$(pwd)" = "/" ]; then
            break
        fi
        if [ -e "$(pwd)/${dotfile}" ] &&
               [ "$(pwd)/${dotfile}" != "${HOME}/${dotfile}" ]
        then
            lines+="`cat $(pwd)/${dotfile}`"
            lines+=$'\n'
        fi
        cd ..
    done
    if [ -e "${HOME}/${dotfile}" ]; then
        lines+="`cat ${HOME}/${dotfile}`"
        lines+=$'\n'
    fi
    echo "${lines}"
}

-execop-confirm-command() {
    local cmd="${1}"
    read -p $'\e[35m[ExeCop] Do you really want to execute \'\e[;1m'"${cmd}"$'\e[0m\e[35m\'?\e[0m [yes/no] '
    if [ "$REPLY" = "yes" ]; then
        :
    else
        -execop-deny-command "${cmd}"
    fi
}

-execop-deny-command() {
    local cmd="${1}"
    echo "[ExeCop] Canceled '${cmd}'." && kill -INT 0
}

execop-preexec-hook () {
    [ -n "$COMP_LINE" ] && return
    [ "$BASH_COMMAND" = "$PROMPT_COMMAND" ] && return
    local cmd=''
    cmd=$(HISTTIMEFORMAT='' history 1 | sed -e "s/^[ ]*[0-9]*[ ]*//");
    -execop-preexec "${cmd}"
}

trap 'execop-preexec-hook' DEBUG
