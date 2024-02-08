# zvm - Zig Version Manager

A script to manage your [zig](https://ziglang.org) versions.

## Getting Started

### Prerequisites

- [`jq`](https://jqlang.github.io/jq/)
- [`curl`](https://curl.se/download.html)

### Usage

## Commands

### list

List zig versions.

```shell
zvm list
zvm list --remote
```

### install

Install a zig version.

```shell
zvm install 0.11.0
```

### use

Use an installed zig version.

```shell
zvm use 0.11.0
```

### uninstall

Uninstall a zig version.

```shell
zvm uninstall 0.10.0
```

### help

Show zvm help.

```shell
zvm help
```

## Customizing

### Environment

- `ZVM_HOME` - zvm home directory (where zvm downloads and extracts zig tarballs)
- `ZVM_BIN` - zvm bin directory (where zvm links zig binaries)

## TODO

- [ ] Support building from source?
- [x] Allow custom download location (default: `$HOME/.local/share/zvm`)
    - 9b1afd4
- [x] Allow custom install prefix (default: `$HOME/.local/bin/zig`)
    - 9b1afd4
