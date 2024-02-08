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
zvm list --remote
zvm list --installed
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

## TODO

- [ ] Allow custom download location (default: `$HOME/.local/share/zvm`)
- [ ] Allow custom install prefix (default: `$HOME/.local/bin/zig`)
- [ ] Support building from source?
