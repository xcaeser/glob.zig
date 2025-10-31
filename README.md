# 📂 glob.zig - a powerful glob matcher

Fast and reliable glob pattern matching in pure zig.

[glob.zig reference docs](https://xcaeser.github.io/glob.zig)

[![Tests](https://github.com/xcaeser/glob.zig/actions/workflows/main.yml/badge.svg)](https://github.com/xcaeser/glob.zig/actions/workflows/main.yml)
[![Zig Version](https://img.shields.io/badge/Zig_Version-0.16.0--dev-orange.svg?logo=zig)](README.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-lightgrey.svg?logo=cachet)](LICENSE)
[![Built by xcaeser](https://img.shields.io/badge/Built%20by-@xcaeser-blue)](https://github.com/xcaeser)
[![Version](https://img.shields.io/badge/glob-v0.1.0-green)](https://github.com/xcaeser/glob.zig/releases)

## 🚀 Features

- Fast glob pattern matching with `*`, `?`, and character classes `[abc]`, `[a-z]`
- Negation support with `!` prefix
- Pattern validation for common errors
- Multiple pattern matching (`matchAny`, `matchAll`)
- No dependencies, pure Zig
- Comprehensive test suite

## 📦 Installation

```sh
zig fetch --save=glob https://github.com/xcaeser/glob.zig/archive/v0.1.0.tar.gz
```

Add to your `build.zig`:

```zig
const glob_dep = b.dependency("glob", .{ .target = target, .optimize = optimize });
exe.root_module.addImport("glob", glob_dep.module("glob"));
```

## 🧪 Example

```zig
const std = @import("std");
const glob = @import("glob");

pub fn main() !void {
    // Simple match
    const matches = glob.match("*.zig", "main.zig");
    std.debug.print("Matches: {}\n", .{matches}); // true

    // Character class
    const class_match = glob.match("test_[0-9].txt", "test_5.txt");
    std.debug.print("Class match: {}\n", .{class_match}); // true

    // Negation
    const negated = glob.match("!*.tmp", "file.txt");
    std.debug.print("Negated: {}\n", .{negated}); // true

    // Multiple patterns
    const patterns = &[_][]const u8{ "*.zig", "*.c", "*.h" };
    const multi = glob.matchAny(patterns, "main.zig");
    std.debug.print("Any match: {}\n", .{multi}); // true

    // Validate pattern
    glob.validate("[a-z]*") catch |err| {
        std.debug.print("Invalid pattern: {}\n", .{err});
        return;
    };
}
```

## 📚 API

### `match(pattern: []const u8, text: []const u8) bool`

Matches text against a glob pattern.

Supported wildcards:

- `*` — matches any number of characters
- `?` — matches any single character
- `[abc]` — matches one character from the set
- `[a-z]` — matches one character from the range
- `!` — negates the pattern (must be first character)

### `validate(pattern: []const u8) !void`

Validates a pattern for syntax errors.

### `matchAny(patterns: []const []const u8, text: []const u8) bool`

Returns true if text matches any of the patterns.

### `matchAll(patterns: []const []const u8, text: []const u8) bool`

Returns true if text matches all of the patterns.

## 📝 License

MIT. See [LICENSE](LICENSE). Contributions welcome.
