#compdef zvm

if ! command -v zvm &> /dev/null; then
    return
fi

local -a zvm_commands
local -a zvm_aliases
local -a zvm_global_options
local -a zvm_list_options
local -a zvm_install_options
local -a zvm_uninstall_options

local -a zvm_local_versions
local -a zvm_remote_versions

zvm_commands=(
    'list:List versions'
    'use:Use installed version'
    'install:Install version'
    'uninstall:Uninstall version'
    'prune:Uninstall all unused versions'
    'help:Show help'
)

zvm_aliases=(
    'ls:List versions'
    'i:Install version'
    'rm:Uninstall version'
    'h:Show help'
)

zvm_global_options=(
    '(-h --help)'{-h,--help}'[Show help]'
    '(-t --target)'{-t,--target}'[Specify target]'
    '(-v)-v[Print version and exit]'
    '(--verbose)--verbose[Show verbose output]'
    '(-vv)-vv[Enable more verbose output]'
)

zvm_list_options=(
    '(-i --installed)'{-i,--installed}'[List installed versions only]'
)

zvm_install_options=(
    '(-e,--exact)'{-e,--exact}"[Attempt to install version, even if it doesn't exist in remote index]"
    '(-s,--src)'{-s,--src}'[Build from source]'
    '(-u,--use)'{-u,--use}'[Make version active after installing]'
)

zvm_uninstall_options=(
    '(-f,--force)'{-f,--force}'[Forcefully uninstall, even if version is active]'
    '(-l,--use-latest)'{-l,--use-latest}'[Fallback to latest version after uninstalling]'
)

_arguments -C \
    $zvm_global_options \
    "1: :{_describe 'command' zvm_commands -- zvm_aliases}" \
    "*::arg:->args"

case $line[1] in
    ls | list)
        _arguments $zvm_list_options
        ;;
    i | install)
        zvm_remote_versions=(${(f)"$(zvm list)"})
        _arguments \
            $zvm_install_options \
            "*:: :{_describe 'command' zvm_remote_versions}"
        ;;
    use)
        zvm_local_versions=(${(f)"$(zvm list --installed)"})
        _arguments \
            "1: :{_describe 'command' zvm_local_versions}"
        ;;
    rm | uninstall)
        zvm_local_versions=(${(f)"$(zvm list --installed)"})
        _arguments \
            $zvm_uninstall_options \
            "1: :{_describe 'command' zvm_local_versions}"
        ;;
esac
