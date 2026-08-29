# glob.zig

Allocation-free glob matching for byte strings in pure Zig.

[Reference docs](https://xcaeser.github.io/glob.zig)

[![Tests](https://github.com/xcaeser/glob.zig/actions/workflows/main.yml/badge.svg)](https://github.com/xcaeser/glob.zig/actions/workflows/main.yml)
[![Zig Version](https://img.shields.io/badge/Zig-0.17.0-orange.svg?logo=zig)](build.zig.zon)
[![License: MIT](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)
[![Version](https://img.shields.io/badge/glob-v0.2.0-green)](https://github.com/xcaeser/glob.zig/releases)

## Features

- `*`, `?`, sets (`[abc]`), ranges (`[a-z]`), and negated sets (`[!abc]`, `[^abc]`)
- Backslash escaping and whole-pattern negation with a leading `!`
- Optional pathname, leading-period, no-escape, and ASCII case-insensitive behavior
- Configurable matching reports malformed patterns
- Constant stack use, no allocation, and no dependencies
- Multiple-pattern helpers: `matchAny` and `matchAll`

Matching is byte-oriented. `?` consumes one byte, not one Unicode scalar.

## Installation

```sh
zig fetch --save=glob https://github.com/xcaeser/glob.zig/archive/v0.2.0.tar.gz
```

Add the module to your executable or library:

```zig
const glob_dep = b.dependency("glob", .{ .target = target, .optimize = optimize });
exe.root_module.addImport("glob", glob_dep.module("glob"));
```

## Usage

```zig
const std = @import("std");
const glob = @import("glob");

pub fn main() !void {
    std.debug.assert(glob.match("src/*.zig", "src/main.zig"));
    std.debug.assert(glob.match("file[0-9].txt", "file7.txt"));
    std.debug.assert(glob.match("!*.tmp", "notes.txt"));
    std.debug.assert(glob.matchAll(&.{ "*.txt", "!test_*" }, "notes.txt"));

    const path = try glob.matchWithOptions("src/*.zig", "src/lib/main.zig", .{
        .pathname = true,
    });
    std.debug.assert(!path); // * cannot cross /

    const readme = try glob.matchWithOptions("README.*", "readme.md", .{
        .case_sensitivity = .insensitive_ascii,
    });
    std.debug.assert(readme);

    try glob.validate("[a-z]*");
}
```

## API

- `match(pattern, text) bool` — the default. Malformed patterns return `false`.
- `matchWithOptions(pattern, text, options) !bool` — configurable matching;
  malformed patterns return a `ValidationError`.
- `validate(pattern) !void` — validate default pattern syntax without matching.
- `matchAny(patterns, text) bool` — match at least one default-syntax pattern.
- `matchAll(patterns, text) bool` — match every default-syntax pattern.

## Pattern syntax

| Pattern            | Meaning                         |
| ------------------ | ------------------------------- |
| `*`                | Zero or more bytes              |
| `?`                | Exactly one byte                |
| `[abc]`            | One byte in the set             |
| `[a-z]`            | One byte in the inclusive range |
| `[!abc]`, `[^abc]` | One byte outside the set        |
| `\*`, `\?`, `\[`   | Escaped literal byte            |
| `!pattern`         | Negate the whole pattern        |

`-` is literal at either edge of a class or when escaped. Invalid patterns
return `false` from `match`; `matchWithOptions` reports `UnclosedBracket`,
`EmptyBracket`, `InvalidRange`, or `TrailingBackslash`.

## Options

`matchWithOptions` accepts:

- `case_sensitivity = .insensitive_ascii` — fold ASCII letter case
- `pathname = true` — wildcards and classes cannot match `/`
- `period = true` — a leading `.` must be matched by a literal `.`; with
  `pathname`, this also applies after `/`
- `no_escape = true` — treat `\` as an ordinary byte

`matchAny` treats every pattern independently, including negated patterns.
Use `matchAll(&.{ "*.txt", "!test_*" }, text)` for an include-and-exclude
filter. The list helpers intentionally use default options; for custom options,
loop over the patterns and call `matchWithOptions` explicitly.

## Development

```sh
zig fmt --check .
zig build test --summary all
zig build docs
```

MIT licensed. See [LICENSE](LICENSE) and [CONTRIBUTING.md](CONTRIBUTING.md).
