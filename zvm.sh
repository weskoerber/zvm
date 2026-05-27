#!/bin/sh

set -euo pipefail

ZVM_HOME=${ZVM_HOME:-"$HOME/.local/share/zvm.sh"}
ZVM_BIN=${ZVM_BIN:-"$HOME/.local/bin"}
ZVM_MIRROR="${ZVM_MIRROR:-}"
ZVM_MIRRORLIST="${ZVM_MIRRORLIST:-https://ziglang.org/download/community-mirrors.txt}"

readonly required_progs="curl,jq,sha256sum,tar,unzip"
os="$(uname | tr '[:upper:]' '[:lower:]')"
readonly os
arch="$(uname -m)"
readonly arch
readonly native_target="${arch}-${os}"
readonly bin_name="zig"
self_name="$(basename "$0")"
readonly self_name
readonly self_version="0.2.1"
readonly versions_file="${ZVM_HOME}/versions.json"
readonly mirrors_file="${ZVM_HOME}/mirrors.txt"

# Global options
o_verbose=0
o_extra_verbose=0
o_target="$native_target"

################################################################################
# Logging functions                                                            #
################################################################################
vrb() {
    if [ $o_verbose -eq 1 ]; then
        echo "vrb: ${1}" >&2
    fi
}

vrb2() {
    if [ $o_extra_verbose -eq 1 ]; then
        echo "vrb: ${1}" >&2
    fi
}

warn() {
    echo "warn: ${1}" >&2
}

err() {
    echo "err: ${1}" >&2
}

die() {
    echo "fatal: ${1}" >&2 && exit 1
}

panic_missing_prog() {
    command -v "$1" > /dev/null 2>&1 || die "'${1}' is required to run this script"
}

################################################################################
# Mirror functions                                                             #
################################################################################
# Initialize the mirror list
mirrors_init() {
    [ -f "$mirrors_file" ] || mirrors_init_force

    now="$(date --date=now +%s)"
    mod="$(stat -c %Y "$mirrors_file")"
    age=$((now-mod))
    if [ $age -gt 86400 ]; then
        mirrors_init_force
    fi
}

mirrors_init_force() {
    vrb 'syncing community mirrors'

    mkdir -p "$ZVM_HOME"

    curl -fs "$ZVM_MIRRORLIST" -o "$mirrors_file" || die "syncing community mirrors failed"
}

# Retrieve a mirror from the mirror list at random
mirror_random() {
    file_data=$(cat "$mirrors_file")

    count=$(echo "$file_data" | wc -l)
    i=$(shuf -i 1-"$count" -n 1)
    mirror=$(echo "$file_data" | head -"$i" | tail -1)

    vrb "download mirror is '$mirror' ($i of $count)"

    echo "$mirror"
}

################################################################################
# Index functions                                                              #
################################################################################
# Initialize the local index file
index_init() {
    mkdir -p "$ZVM_HOME"

    versions=$(jq . "$versions_file" 2> /dev/null)
    if ! [ -e "${versions_file}" ] || [ -z "${versions}" ] || [ "${versions}" = 'null' ]; then
        echo '{"releases": {}, "active": null}' | jq > "$versions_file"
    else
        if ! [ -f "$versions_file" ]; then
            die "version manifest file is not a regular file"
        fi
    fi
}

# Read the local index
index_fetch_local() {
    vrb "reading local index from ${versions_file}"

    jq . "$versions_file"
}

# Read the remote index
index_fetch_remote() {
    mirrors_init
    ZVM_MIRROR="${ZVM_MIRROR:-"$(mirror_random)"}"
    index="$ZVM_MIRROR/index.json"

    vrb "fetching remote index from $index"
    if ! curl_output=$(curl -fs "$index"); then
        err "failed fetching index"
        err "curl: $curl_output"
    else
        vrb "successfully fetched index"
        echo "$curl_output"
    fi
}

# List versions from the local index
index_list_local() {
    index_fetch_local | jq -r '.releases|keys[]'
}

# List versions passed via stdin
index_list() {
    cat - | jq -r 'keys_unsorted|.[]'
}

# Add a release to the local index
# args:
#   $1  Release name
#   $2  Release JSON object
index_add_release() {
    _version=$1
    _json=$2

    vrb "adding release '$_version' to local index"

    current=$(cat "$versions_file")

    echo "$current" | jq --argjson r "$_json" ".releases.\"$_version\"=\$r" > "$versions_file"
}

# Set release active
# args:
#   $1  Release name
index_set_active() {
    _version=$1

    vrb "marking '$_version' installed"

    current=$(cat "$versions_file")
    echo "$current" | jq ".active=\"$_version\"" > "$versions_file"
}

# Get the active version
index_get_active() {
    version=$(jq -r '.active' "$versions_file")
    if [ "$version" = 'null' ]; then
        version=""
    fi

    echo "$version"
}

# Remove active version (sets active field to null, doesn't remove anything)
index_remove_active() {
    current=$(cat "$versions_file")
    echo "$current" | jq ".active=null" > "$versions_file"
}

# Convert the master tag to a semver by reading index passed via stdin
index_get_master_version() {
    vrb "resolving master version from index"

    master_version="$(cat - | jq -r '.master.version')"

    if [ -z "$master_version" ] || [ "$master_version" = 'null' ]; then
        err "failed retrieving master version from remote index"
        exit 1
    fi

    echo "$master_version"
}

################################################################################
# File functions                                                               #
################################################################################

# Download a file
# args:
#   $1  release name
#   $2  release JSON object
file_download() {
    _version=$1
    _json=$2

    info=$(echo "$_json" | jq ".\"$o_target\"")

    if [ "$info" = 'null' ]; then
        die "target '$o_target' not supported"
    fi

    tarball=$(echo "$info" | jq -r '.tarball')

    extension=''
    case "$tarball" in
        *.tar.xz)
            extension='.tar.xz'
            ;;
        *.zip)
            extension='.zip'
            ;;
        *)
            die "unsupported extension '$extension'"
            ;;
    esac

    shasum=$(echo "$info" | jq -r '.shasum')

    filename="${_version}${extension}"
    path="$ZVM_HOME/$_version/$filename"
    dir=$(dirname "$path")

    mkdir -p "$dir"

    vrb "downloading $tarball ($extension) to $dir"

    echo "$shasum *$path" > "$path.shasum"
    if ! curl -fs --output "$path" \
        --get --data 'source=weskoerber-zvm.sh' \
        "$tarball" > /dev/null 2>&1; then
        die "download failed"
    fi

    vrb "verifying shasum"

    sha256sum --status --check "$path.shasum"
    sha_result=$?

    if [ $sha_result -ne 0 ]; then
        err "shasum failed for $path"
        exit 1
    fi

    vrb "shasum verified"
    vrb "extracting $filename"

    if [ "$extension" = '.tar.xz' ]; then
        tar --strip-components=1 -xf "$path" -C "$dir"
    elif [ "$extension" = '.zip' ]; then
        unzip -q "$path" -d "$dir"
        mv "$dir/zig-*/*" "$dir"
        rm -r "$dir/zig-*"
    fi

    vrb "cleaning up"

    rm "$path"
    rm "$path.shasum"
}

# Download a file without release JSON from the index
# args:
#   $1  release name
file_download_no_checksum() {
    _version=$1

    case "$o_target" in
        *windows*)
            extension='.zip'
            ;;
        *)
            extension='.tar.xz'
            ;;
    esac

    _arch=$(echo "${o_target}" | cut -d - -f 1)
    _os=$(echo "${o_target}" | cut -d - -f 2)

    tarball="https://ziglang.org/builds/zig-${_os}-${_arch}-${_version}${extension}"

    filename="${_version}${extension}"
    path="$ZVM_HOME/$_version/$filename"
    dir=$(dirname "$path")

    mkdir -p "$dir"

    vrb "downloading $tarball ($extension) to $dir"

    if ! curl -fs --output "$path" \
        --get --data 'source=weskoerber-zvm.sh' \
        "$tarball" > /dev/null 2>&1; then
        die "download failed"
    fi

    size=$(du -b "$path" | awk '{print $1}')

    vrb "extracting $filename"

    if [ "$extension" = '.tar.xz' ]; then
        tar --strip-components=1 -xf "$path" -C "$dir"
    elif [ "$extension" = '.zip' ]; then
        unzip -q "$path" -d "$dir"
        mv "$dir/zig-*/*" "$dir"
        rm -r "$dir/zig-*"
    fi

    vrb "cleaning up"

    rm "$path"

    echo "{\"${o_target}\":{\"tarball\":\"${tarball}\",\"size\":${size}}}"
}

################################################################################
# Command functions                                                            #
################################################################################

# command: list
# args: none
# options:
#   -i, --installed  List versions from the local index instead of remote
o_remote=1
cmd_list() {
    for _ in "$@"; do
        case $1 in
            -i|--installed)
                o_remote=0
                shift
                ;;
            *)
                err "unrecognized argument: '$1'"
                exit 1
        esac
    done

    active="$(index_get_active)"

    index=''
    list=''

    if [ $o_remote -eq 1 ]; then
        index="$(index_fetch_remote)"
        list="$(echo "$index" | index_list | sort -Vr)"
    else
        list="$(index_list_local | sort -Vr)"
    fi

    for v in $list; do
        entry=''
        resolved_version=''
        if [ "$v" = 'master' ]; then
            resolved_version="$(echo "$index" | index_get_master_version)"
            entry="$resolved_version ($v)"
        else
            resolved_version="$v"
            entry="$v"
        fi

        if [ "$resolved_version" = "$active" ]; then
            entry="$entry (active)"
        fi

        echo "$entry"
    done

}

# command: use
# args:
#   $1  Version name from index
# options: none
cmd_use() {
    _version=$1

    if [ -z "$_version" ]; then
        err "expected 1 positional argument"
        exit 1
    fi

    if [ "$_version" = 'master' ]; then
        _version=$(index_fetch_remote | index_get_master_version)
    fi

    installed=$(index_fetch_local | jq -r ".releases.\"$_version\"")
    if [ "$installed" = 'null' ]; then
        err "version '$_version' is not installed; install it with '$self_name install $_version'"
        exit 1
    fi

    src="$ZVM_HOME/$_version/$bin_name"
    dst="$ZVM_BIN/$bin_name"

    case "$o_target" in
        *windows*)
            src="$src.exe"
            dst="$dst.exe"
            ;;
    esac

    # TODO: get the path to the dir
    if ! [ -f "$src" ]; then
        err "file not found: $src"
    fi

    ln -sf "$src" "$dst"

    index_set_active "$_version"
}

cmd_which() {
    _active_version="$(index_get_active)"

    if [ -z "$_active_version" ]; then
        exit 1
    fi

    echo "$ZVM_HOME/$_active_version"
}

# command: install
# args:
#   $1  Version name from index
# options:
#   -e, --exact  Attempt to install version, even if it doesn't exist in the
#                index
#   -u, --use    Make active immediately after install
o_exact=0
o_use=0
cmd_install() {
    for _ in "$@"; do
        case $1 in
            -e|--exact)
                o_exact=1
                shift
                ;;
            -u|--use)
                o_use=1
                shift
                ;;
        esac
    done

    _version=$1

    if [ $o_exact -eq 1 ]; then
        if ! json=$(file_download_no_checksum "$_version"); then
            err "failed installing $_version"
            exit 1
        fi
    else
        index_version=$_version
        index="$(index_fetch_remote)"

        if [ "${_version}" = 'master' ]; then
            _version="$(echo "$index" | index_get_master_version)"
        fi

        vrb "installing '$_version'"

        installed=$(index_fetch_local | jq -r ".releases.\"$_version\"")
        if [ "$installed" != 'null' ]; then
            err "version '$_version' is already installed; see '$self_name use $_version'"
            exit 1
        fi

        json=$(echo "$index" | jq -r ".\"$index_version\"")
        if [ "${json}" = 'null' ] && [ $o_exact -eq 0 ]; then
            err "version '$index_version' not found in remote index"
            exit 1
        fi

        if ! file_download "$_version" "$json"; then
            err "failed installing $_version"
            exit 1
        fi
    fi

    index_add_release "$_version" "$json"

    if [ $o_use -eq 1 ]; then
        cmd_use "$_version"
    fi
}

# command: prune
# args: none
# options: none
cmd_prune() {
    active=$(jq -r '.active' "$versions_file")
    installed=$(index_list_local)

    vrb "pruning unused versions"

    for version in $installed; do
        if [ "$active" = "$version" ];then
            vrb "skipping active version '$active'"
            continue
        fi

        vrb "uninstalling '$version'"

        cmd_uninstall "$version"
    done
}

# command: uninstall
# args:
#   $1: Version to uninstall
# options:
#   -f, --force       Forcefully uninstall, even if version is active
#   -l, --use-latest  Fallback to latest version after uninstalling
o_force=0
o_use_latest=0
cmd_uninstall() {
    for _ in "$@"; do
        case $1 in
            -f|--force)
                o_force=1
                shift
                ;;
            -l|--use-latest)
                o_use_latest=1
                shift
                ;;
        esac
    done
    _version=$1

    installed=$(jq ".releases.\"$_version\"" "$versions_file")
    if [ -z "$installed" ] || [ "$installed" = 'null' ]; then
        err "version '$_version' is not installed"
        exit 1
    fi

    current_install=$(jq -r '.active' "$versions_file")
    if [ "$current_install" = "$_version" ] && [ $o_use_latest -eq 0 ]; then
        if [ $o_force -eq 0 ]; then
            err "will not remove active version (use -f to force, or -l to fallback to latest)"
            exit 1
        fi

        warn "active version was uninstalled; use '$self_name use <version>' to switch to an available version"
        index_remove_active
    fi

    vrb "removing files from disk"

    dir="$ZVM_HOME/$_version"
    rm -rf "$dir"

    if [ -e "$ZVM_BIN/$bin_name" ]; then
        if [ "$_version" = "$current_install" ]; then
            unlink "$ZVM_BIN/$bin_name"
        fi
    else
        vrb "skipping non-existent symlink"
    fi

    vrb "removing from index"
    json=$(jq . "$versions_file")
    echo "$json" | jq "del(.releases.\"$_version\")" > "$versions_file"

    if [ $o_use_latest -eq 1 ]; then
        cmd_use "$(index_list_local | tail -n 1)"
    fi
}

# command: mirror
# options:
#   -r, --refresh       Refresh mirror list
o_refresh=0
cmd_mirror() {
    for _ in "$@"; do
        case $1 in
            ls) cat "$mirrors_file"
                ;;
            -r|--refresh)
                o_refresh=1
                shift
                ;;
            *)
                err "unrecognized argument: '$1'"
                exit 1
        esac
    done

    if [ $o_refresh -eq 1 ]; then
        mirrors_init_force
    fi
}

################################################################################
# Helper functions                                                             #
################################################################################

# Print usage and exit
usage() {
    cat >&2 <<usage_text
$self_name - Zig Version Manager

Usage: zvm.sh [OPTIONS] [command] [...]

Options:
  -t, --target  Specify a custom target to use
  -v            Enable verbose script output
  -vv           Enable even more verbose output
  --version     Print the version and exit

Commands:
  list [OPTIONS]                 List Zig versions available in the remote index
    -i, --installed              List installed Zig versions

  install [OPTIONS] <version>    Install a Zig version
    -e, --exact                  Attempt to install version, even if it doesn't
                                 exist in the remote index
    -u, --use                    Make version active immediately

  use <version>                  Use an installed Zig version

  which                          Print the path of the active Zig version

  uninstall [OPTIONS] <version>  Uninstall a Zig version
    -l, --use-latest             Fallback to latest version after uninstalling
    -f, --force                  Forcefully uninstall, even if version is active

  mirror [OPTIONS] [COMMAND]     List/manage mirrors
    -r, --refresh                Fetch and overwrite community mirror list
    ls                           List community mirror list
  prune                          Uninstall all but the currently active version
  help                           Show this help page

Aliases:
  list: ls
  install: i
  uninstall: rm
  help: h

Environment:
  ZVM_HOME  Path where zvm downloads and extracts zig releases
              Default: \$HOME/.local/share/zvm.sh/

  ZVM_BIN        Path where zvm symlinks zig binaries
  ZVM_MIRROR     URL to mirror. If set, zvm will not choose a random one from
                 ZVM_MIRRORLIST
 ZVM_MIRRORLIST  List of mirrors zvm considers
usage_text
}

# Ensure all required programs are installed, and panic otherwise
ensure_required_progs() {
    (
        IFS=','; for prog in $required_progs; do
            panic_missing_prog "$prog"
        done
    )
}

# Parse global options (options before command)
args_parse_global() {
    for _ in "$@"; do
        case $1 in
            # Parse global options
            -h | --help | h | help)
                usage
                exit 0
                ;;
            -t | --target)
                shift
                o_target="$1"
                shift
                ;;
            -vv)
                o_extra_verbose=1
                o_verbose=1
                shift
                ;;
            -v | --verbose)
                o_verbose=1
                shift
                ;;
            --version)
                echo "$self_version" >&2
                exit 0
                ;;
            *)
                break
                ;;
        esac
    done

    echo "$@"
}

# Parse command and call its function
args_parse_command() {
    if [ $# -eq 0 ]; then
        index_get_active
        exit 0
    fi

    for _ in "$@"; do
        case $1 in
            # Parse commands
            ls|list)
                shift
                cmd_list "$@"
                exit $?
                ;;
            i|install)
                shift
                cmd_install "$@"
                exit $?
                ;;
            prune)
                shift
                cmd_prune "$@"
                exit $?
                ;;
            rm|uninstall)
                shift
                cmd_uninstall "$@"
                exit $?
                ;;
           use)
                shift
                cmd_use "$@"
                exit $?
                ;;
           which)
               shift
               cmd_which "$@"
               exit $?
               ;;
           mirror)
               shift
               cmd_mirror "$@"
               exit $?
               ;;
            *)
                echo "unrecognized command '$1'"
                ;;
        esac
    done
}

assume_target() {
    assumed_os="$os"

    case "$os" in
        *mingw*)
            assumed_os='windows'
            ;;
    esac

    o_target="${arch}-${assumed_os}"
}

################################################################################
# Script start                                                                 #
################################################################################

! [ -d "$ZVM_HOME" ] && mkdir -p "$ZVM_HOME" > /dev/null
! [ -d "$ZVM_BIN" ] && mkdir -p "$ZVM_BIN" > /dev/null

ensure_required_progs
index_init
assume_target

# TODO(cleanup): have to call args_parse_global twice: first to set global
# options, then to get command without global options
args_parse_global "$@" > /dev/null

# TODO: clean this up... we don't know which options, if any, are provided
# before this line
vrb2 "zvm version: $self_version"
vrb2 "ZVM_HOME: $ZVM_HOME"
vrb2 "ZVM_BIN: $ZVM_BIN"
vrb2 "native_target: $native_target"
vrb2 "target: $o_target"

# shellcheck disable=SC2046
args_parse_command $(args_parse_global "$@")
