autoload -Uz add-zsh-hook
add-zsh-hook preexec -execop-preexec

-execop-preexec() {
    local conditions=`-execop-gather-dotfiles`
    local cmd="${1}"
    if [ $conditions = '' ]; then
        return
    fi
    local IFS=$'\n'
    local conditions=( `echo $conditions` )
    for line in ${conditions}; do
        local IFS=' '
        local arr=( `echo $line` )
        local action=${arr[1]}
        local matcher=${arr[3]}
        local cmd_or_env="$(IFS=,; echo "${arr[@]:3}")"
        if [ ! $cmd_or_env ]; then
            continue
        fi
        if [ ${arr[2]} != 'when' ]; then
            continue
        fi

        ## command_match
        if [ $matcher = 'command_match' ]; then
            if [[ $cmd =~ $cmd_or_env ]]; then
                if [ $action = 'deny' ]; then
                    -execop-deny-command $cmd
                fi
                if [ $action = 'confirm' ]; then
                    -execop-confirm-command $cmd
                fi
            fi
        fi

        ## command_not_match
        if [ $matcher = 'command_not_match' ]; then
            if [[ ! $cmd =~ $cmd_or_env ]]; then
                if [ $action = 'deny' ]; then
                    -execop-deny-command $cmd
                fi
                if [ $action = 'confirm' ]; then
                    -execop-confirm-command $cmd
                fi
            fi
        fi

        ## command_eq
        if [ $matcher = 'command_eq' ]; then
            if [ $cmd = $cmd_or_env ]; then
                if [ $action = 'deny' ]; then
                    -execop-deny-command $cmd
                fi
                if [ $action = 'confirm' ]; then
                    -execop-confirm-command $cmd
                fi
            fi
        fi

        ## command_not_eq
        if [ $matcher = 'command_not_eq' ]; then
            if [ $cmd != $cmd_or_env ]; then
                if [ $action = 'deny' ]; then
                    -execop-deny-command $cmd
                fi
                if [ $action = 'confirm' ]; then
                    -execop-confirm-command $cmd
                fi
            fi
        fi

        ## env_eq
        if [ $matcher = 'env_eq' ]; then
            local IFS='=';
            local splitted=( `echo $cmd_or_env` );
            local envname=${splitted[1]}
            local envvalue=${splitted[2]}
            local actual="$(eval echo '$'$envname)"
            if [ $actual ] && [ $envvalue != $actual ]; then
                if [ $action = 'deny' ]; then
                    -execop-deny-command $cmd
                fi
                if [ $action = 'confirm' ]; then
                    -execop-confirm-command $cmd
                fi
            fi
        fi

        ## env_not_eq
        if [ $matcher = 'env_not_eq' ]; then
            local IFS='='; splitted=( `echo $cmd_or_env` );
            local envname=${splitted[1]}
            local envvalue=${splitted[2]}
            local actual="$(eval echo '$'$envname)"
            if [ $actual ] && [ $envvalue != $actual ]; then
                if [ $action = 'deny' ]; then
                    -execop-deny-command $cmd
                fi
                if [ $action = 'confirm' ]; then
                    -execop-confirm-command $cmd
                fi
            fi
        fi
    done
}

-execop-gather-dotfiles() {
    local dotfile='.execop'
    local conditions=''
    while :
    do
        if [ "$(pwd)" = "/" ]; then
            break
        fi
        if [ -e "$(pwd)/${dotfile}" ]; then
            conditions+="`cat $(pwd)/${dotfile}`"
            conditions+="\n"
        fi
        cd ..
    done
    echo $conditions
}

-execop-confirm-command() {
    local cmd="${1}"
    local answer=''
    if vared -c -p "[ExeCop] Do you really want to execute '${cmd}'? [yes/no] " answer &&
            [[ -n $answer && $answer = 'yes' ]]
    then
        # execute!
    else
        -execop-deny-command $cmd
    fi
}

-execop-deny-command() {
    local cmd="${1}"
    echo "[ExeCop] Canceled '${cmd}'." && kill -INT 0
}
