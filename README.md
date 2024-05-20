# zvm - Zig Version Manager

A script to manage your [Zig](https://Ziglang.org) versions.

## Getting Started

First, make sure `ZVM_BIN` is on your `PATH`. By default, it's `~/.local/bin`:[^1]
- On Linux, `/home/<username>/.local/bin`
- On Windows, `C:\Users\<username>\.local\bin`
- On MacOS, `/Users/<username>/.local/bin`

Next, determine if you need to explicitly set your target. On Linux you
probably won't have to, put if you're on Windows or MacOS, see the
[Cross-platform support](#cross-platform-support) section below.

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

Native support. `zvm`'s detected native target will likely work, but you can
override it if you need to.

### Windows

Supported via various Linux subsystems (git-bash, WSL, etc.).

`zvm` uses `uname` to detect the target and it currently only uses what `uname`
provides, which will differ depending on the Linux subsystem used (git-bash,
WSL, mingw, etc). However, [Zig's
targets](https://ziglang.org/documentation/master/std/#std.Target.Os.Tag) use
`windows` as the OS name. Due to this, for now you'll have to explicitly set
your target:

```shell
zvm --target <arch>-windows
```

Replace `<arch>` with one of the following:
- On a 32-bit system, `x86` (e.g. `x86-windows`)
- On a 64-bit x86 system, `x86-64` (e.g. `x86_64-windows`)
- On a 64-bit aarch64 system, aarch64 (e.g. `aarch64-windows`)

### MacOS

Supported natively but shares the same gotchas as the Windows support.

`zvm` uses `uname` to detect the target and it currently only uses what `uname`
provides. However, [Zig's
targets](https://ziglang.org/documentation/master/std/#std.Target.Os.Tag) use
`macos` as the OS name instead of `darwin`, which is what `uname` will return.
Due to this, for now you'll have to explicitly set your target:

```shell
zvm --target <arch>-macos
```

Replace `<arch>` with one of the following:
- On a 64-bit x86 system, `x86-64` (e.g. `x86_64-macos`)
- On a 64-bit aarch64 system (a.k.a 'Apple silicon'), `aarch64` (e.g.
  `aarch64-macos`)

---

[^1]: You can override this path with the `ZVM_BIN` environment variable. See
    the [Environment](#environment) section for details.
