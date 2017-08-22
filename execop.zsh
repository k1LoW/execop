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
        local type=${arr[3]}
        local condition="$(IFS=,; echo "${arr[@]:3}")"
        if [ ! $condition ]; then
            continue
        fi
        if [ ${arr[2]} != 'when' ]; then
            continue
        fi

        ## command_match
        if [ $type = 'command_match' ]; then
            if [[ $cmd =~ $condition ]]; then
                if [ $action = 'deny' ]; then
                    -execop-deny-command $cmd
                fi
                if [ $action = 'confirm' ]; then
                    -execop-confirm-command $cmd
                fi
            fi
        fi

        ## command_eq
        if [ $type = 'command_eq' ]; then
            if [[ $cmd = $condition ]]; then
                if [ $action = 'deny' ]; then
                    -execop-deny-command $cmd
                fi
                if [ $action = 'confirm' ]; then
                    -execop-confirm-command $cmd
                fi
            fi
        fi

        ## env_eq
        if [ $type = 'env_eq' ]; then
            local IFS='=';
            local splitted=( `echo $condition` );
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
        if [ $type = 'env_not_eq' ]; then
            local IFS='='; splitted=( `echo $condition` );
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
