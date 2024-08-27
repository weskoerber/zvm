# zvm - Zig Version Manager

A script to manage your [Zig](https://ziglang.org) versions.

<img alt="zvm demo" src="https://raw.githubusercontent.com/weskoerber/zvm/main/img/zvm.gif" width="600" />

## Features

- Single POSIX-compliant shell script
- Shell completions (bash, zsh)
- Few dependencies (you probably have them installed already)

## Getting Started

First, make sure `ZVM_BIN` is on your `PATH`. By default, it's `~/.local/bin`:[^1]
- On Linux, `/home/<username>/.local/bin`
- On Windows, `C:\Users\<username>\.local\bin`
- On MacOS, `/Users/<username>/.local/bin`

Next, determine if you need to explicitly set your target. On Linux you
probably won't have to. If you're on Windows or MacOS, see the
[Cross-platform support](#cross-platform-support) section below.

### Prerequisites

- A POSIX-compliant shell
- [GNU coreutils](https://www.gnu.org/software/coreutils)
- [curl](https://curl.se/download.html)
- [jq](https://jqlang.github.io/jq/)
- GNU tar
- unzip

If you're building from source (`zvm install --src`), you'll need the
following dependencies, in addition to those listed above:
- [cmake](https://cmake.org) (version 3.15 or newer)
- [git](https://git-scm.org)
- GNU sed

### Usage

Without any commands, `zvm` will print the active Zig version and exit.
Specific actions may be performed my providing a command.

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

By default, the `uninstall` command will prevent the current version from being
uninstalled. To bypass, there are 2 options:
1. Fall back to the newest installed version with `-l,--use-latest`
2. Force removal
    - Note that after forcing removal, the `zig` command will no longer exist
      and you'll have to use the `use` command to select a new version

### `help`

Alias: `h`

Show `zvm` help:
```shell
zvm help
```

## Customizing

### Environment

- `ZVM_HOME` - `zvm` home directory (where `zvm` downloads and extracts Zig tarballs)
- `ZVM_BIN` - `zvm` bin directory (where `zvm` symlinks Zig binaries)

## TODO

- [ ] Support building from source? (in-progress, see #14)
- [x] Allow custom download location (default: `$HOME/.local/share/zvm`)
    - 9b1afd4
- [x] Allow custom install prefix (default: `$HOME/.local/bin/zig`)
    - 9b1afd4

## Cross-platform support

### Linux

Native support. `zvm`'s detected native target will likely work, but you can
override it if you need to.

### Windows

Windows is not natively supported. However, support exists for WSL2 and
`git-bash`.

### MacOS

I have no idea if `zvm` works on MacOS or not. If you're using MacOS and would
like to help bring official support to MacOS, please submit a PR! With that
said, as long as the dependencies exist, MacOS should be supported. You may
need to manually specify your target.

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
