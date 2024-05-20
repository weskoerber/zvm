# zvm - Zig Version Manager

A script to manage your [Zig](https://Ziglang.org) versions.

## Getting Started

### Prerequisites

- A POSIX-compliant shell
- [curl](https://curl.se/download.html)
- [jq](https://jqlang.github.io/jq/)
- tar
- unzip

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

## Cross-platform support

### Linux

Native support.

### Windows

Supported via WSL or git-bash. There's a couple of gotchas, though.

First, add `%USERPROFILE%\.local\bin`[^1] to your `PATH` in Windows, as that is
where `zvm` puts the symlinks. If you don't do this, Windows won't know where
to find the zig executable.

Next, you'll probably want to explicitly define your target. If you don't do
this, `zvm` uses whichever target is provided by the linux subsystem, be it
git-bash, WSL, , mingw, etc. Explicitly setting your target ensures `zvm` finds
the release in zig's download index. You can specify the target with the `-t,
--target` flag, like so:

```shell
zvm --target <arch>-windows
```

Replace `<arch>` with one of the following:
- On a 32-bit system, `x86` (e.g. `x86-windows`)
- On a 64-bit x86 system, `x86-64` (e.g. `x86_64-windows`)
- On a 64-bit aarch64 system, aarch64 (e.g. `aarch64-windows`)

### MacOS

Supported natively but shares the same gotchas as the Windows support.

First, make sure `~/.local/bin` is on your `PATH`.

Next, explicitly set your target:

```shell
zvm --target <arch>-macos
```

Replace `<arch>` with one of the following:
- On a 64-bit x86 system, `x86-64` (e.g. `x86_64-macos`)
- On a 64-bit aarch64 system (a.k.a 'Apple silicon'), `aarch64` (e.g.
  `aarch64-macos`)

---

[^1]: Thats most likely `C:\Users\<your_username>\.local\bin`.
