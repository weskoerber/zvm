# zvm - Zig Version Manager

A script to manage your [Zig](https://Ziglang.org) versions.

## Getting Started

### Prerequisites

- [`jq`](https://jqlang.github.io/jq/)
- [`curl`](https://curl.se/download.html)

### Usage

Without any commands, `zvm` will print the currently active Zig version and
exit. Specific actions may be performed my providing a command.

## Commands

### `list`

Alias: `ls`

List Zig versions from the remote index:
```shell
zvm list
```

List installed Zig versions:
```shell
zvm list -i
zvm list --installed
```

### `install`

Alias: `i`

Install a Zig version:
```shell
zvm install 0.12.0
```

Install a Zig version and make it active immediately:
```shell
zvm install -u 0.12.0
zvm install --use 0.12.0
```

### `use`

Use an installed Zig version:
```shell
zvm use 0.12.0
```

### `uninstall`

Alias: `rm`

Uninstall a Zig version:
```shell
zvm uninstall 0.11.0
```

### `help`

Alias: `h`

Show `zvm` help:
```shell
zvm help
```

## Customizing

### Environment

- `ZVM_HOME` - `zvm` home directory (where `zvm` downloads and extracts Zig tarballs)
- `ZVM_BIN` - `zvm` bin directory (where `zvm` links Zig binaries)

## TODO

- [ ] Support building from source?
- [x] Allow custom download location (default: `$HOME/.local/share/zvm`)
    - 9b1afd4
- [x] Allow custom install prefix (default: `$HOME/.local/bin/zig`)
    - 9b1afd4
