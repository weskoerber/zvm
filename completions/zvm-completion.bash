_zvm_completions()
{
    local cur prev commands options list_options
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    commands="help install list prune uninstall use"
    options="--help --verbose"
    list_options="-i --installed"
    install_options="-u --use"
    uninstall_options="-f --force"

    zvm_local_versions="$(zvm list --installed)"

    # Completing the commands
    if [[ ${COMP_CWORD} -eq 1 ]]; then
        COMPREPLY=( $(compgen -W "${options} ${commands}" -- ${cur}) )
        return 0
    fi

    case "${COMP_WORDS[1]}" in
        ls | list)
            COMPREPLY=( $(compgen -W "${list_options}" -- ${cur}) )
            return 0
            ;;
        i | install)

            COMPREPLY=( $(compgen -W "${install_options} $(zvm list)" -- ${cur}) )
            return 0
            ;;
        rm | uninstall)
            COMPREPLY=( $(compgen -W "${uninstall_options} ${zvm_local_versions}" -- ${cur}) )
            return 0
            ;;
        use)
            COMPREPLY=( $(compgen -W "${zvm_local_versions}" -- ${cur}) )
            return 0
            ;;
    esac

    # Completing the options for `zvm`
    if [[ ${cur} == -* ]]; then
        COMPREPLY=( $(compgen -W "${options}" -- ${cur}) )
        return 0
    fi
}

complete -F _zvm_completions zvm
