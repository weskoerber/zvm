_zvm_completions()
{
    local cur prev commands global_options list_options
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    commands="help install list prune uninstall use"
    global_options="-h --help -t --target -v -vv --verbose"
    list_options="-i --installed"
    install_options="-e --exact -s --src -u --use"
    uninstall_options="-f --force -l --use-latest"

    zvm_local_versions="$(zvm list --installed)"

    # Completing the global options for `zvm`
    if [[ ${COMP_CWORD} -eq 1 ]] && [[ ${cur} == -* ]]; then
        COMPREPLY=( $(compgen -W "${global_options}" -- ${cur}) )
        return 0
    fi

    # Completing the commands
    case ${COMP_CWORD} in
        0)
            # should never happen?
            return 0
            ;;
        1)
            COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
            return 0
            ;;
    esac

    local cmp_list
    case "${COMP_WORDS[1]}" in
        ls | list)
            [[ "${cur}" == -* ]] && cmp_list="${list_options}"
            ;;
        i | install)
            [[ "${cur}" == -* ]] && cmp_list="${install_options}" || cmp_list="$(zvm list)"
            ;;
        rm | uninstall)
            [[ "${cur}" == -* ]] && cmp_list="${uninstall_options}" || cmp_list="${zvm_local_versions}"
            ;;
        use)
            cmp_list="${zvm_local_versions}"
            ;;
    esac
    COMPREPLY=( $(compgen -W "${cmp_list}" -- ${cur}) )
}

complete -F _zvm_completions zvm
