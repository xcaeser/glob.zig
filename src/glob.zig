//! glob.zig — a powerful glob matcher
//!
//! MIT License
//!
//! Author: @xcaeser (GitHub)
//!
//! This module provides simple glob pattern matching functionality,
//! supporting common wildcards such as `*`, `?`, and character ranges
//! like `[a-z]`. It can be used to check whether a given text matches
//! a glob-style pattern.
//!

const std = @import("std");
const expect = std.testing.expect;
const expectError = std.testing.expectError;

pub const ValidationError = error{
    UnclosedBracket,
    EmptyBracket,
    TrailingBackslash,
};

/// Validates a glob pattern for common errors.
///
/// Returns an error if the pattern contains:
/// - Unclosed brackets `[`
/// - Empty brackets `[]`
/// - Trailing backslash `\`
///
/// Returns `void` if the pattern is valid.
///
pub fn validate(pattern: []const u8) ValidationError!void {
    var i: usize = 0;
    while (i < pattern.len) : (i += 1) {
        switch (pattern[i]) {
            '\\' => {
                if (i + 1 >= pattern.len) return error.TrailingBackslash;
                i += 1;
            },
            '[' => {
                const end = std.mem.indexOfScalarPos(u8, pattern, i, ']') orelse return error.UnclosedBracket;
                if (end == i + 1) return error.EmptyBracket;
            },
            else => {},
        }
    }
}

/// Matches a text string against a glob-style pattern.
///
/// Supported wildcards:
///
/// - `*` — matches any number of any characters, including none.
///   Example: `Law*` matches `Law`, `Laws`, and `Lawyer`,
///   but not `GrokLaw`, `La`, or `aw`.
///
/// - `?` — matches any single character.
///   Example: `?at` matches `Cat`, `Bat`, `cat`, and `bat`,
///   but not `at`.
///
/// - `[abc]` — matches one character from the set inside the brackets.
///   Example: `[CB]at` matches `Cat` and `Bat`,
///   but not `cat`, `bat`, or `CBat`.
///
/// - `[a-z]` — matches one character from the given range.
///   Example: `Letter[0-9]` matches `Letter0` through `Letter9`,
///   but not `Letters`, `Letter`, or `Letter10`.
///
/// - `!` prefix — negates the pattern (must be first character).
///   Example: `!*.tmp` matches anything except files ending in `.tmp`.
///
/// Returns `true` if the given text matches the pattern, otherwise `false`.
///
pub fn match(pattern: []const u8, text: []const u8) bool {
    // Handle negation
    if (pattern.len > 0 and pattern[0] == '!') {
        return !matchImpl(pattern[1..], text);
    }
    return matchImpl(pattern, text);
}

fn matchImpl(pattern: []const u8, text: []const u8) bool {
    if (pattern.len == 0) return text.len == 0;
    if (text.len == 0) return pattern.len > 0 and pattern[0] == '*' and matchImpl(pattern[1..], text);

    var p_idx: usize = 0;
    var t_idx: usize = 0;

    while (p_idx < pattern.len and t_idx < text.len) {
        const p_char = pattern[p_idx];

        switch (p_char) {
            '\\' => {
                p_idx += 1;
                if (p_idx >= pattern.len) return false;

                if (pattern[p_idx] != text[t_idx]) return false;
                p_idx += 1;
                t_idx += 1;
            },
            '?' => {
                p_idx += 1;
                t_idx += 1;
            },
            '*' => {
                for (t_idx..text.len + 1) |j| {
                    if (matchImpl(pattern[p_idx + 1 ..], text[j..])) return true;
                }
                return false;
            },
            '[' => {
                const end_bracket = std.mem.indexOfScalarPos(u8, pattern, p_idx, ']') orelse return false;
                if (end_bracket == p_idx + 1) return false; // empty bracket []

                const chars = pattern[p_idx + 1 .. end_bracket];
                const matched = matchCharacterClass(chars, text[t_idx]);
                if (!matched) return false;

                p_idx = end_bracket + 1;
                t_idx += 1;
            },
            else => {
                if (p_char != text[t_idx]) return false;
                p_idx += 1;
                t_idx += 1;
            },
        }
    }

    while (p_idx < pattern.len and pattern[p_idx] == '*') : (p_idx += 1) {}
    return p_idx == pattern.len and t_idx == text.len;
}

/// Matches text against multiple patterns.
///
/// Returns `true` if the text matches ANY of the patterns.
///
/// Example:
/// ```zig
/// const patterns = &[_][]const u8{ "*.zig", "*.c", "*.h" };
/// matchMultiple(patterns, "main.zig") // returns true
/// matchMultiple(patterns, "main.py")  // returns false
/// ```
///
pub fn matchMultiple(patterns: []const []const u8, text: []const u8) bool {
    for (patterns) |pattern| {
        if (match(pattern, text)) return true;
    }
    return false;
}

/// Checks if text matches ANY of the patterns.
///
/// Alias for `matchMultiple` for better readability in some contexts.
///
pub fn matchAny(patterns: []const []const u8, text: []const u8) bool {
    return matchMultiple(patterns, text);
}

/// Checks if text matches ALL of the patterns.
///
/// Returns `true` only if the text matches every single pattern.
///
/// Example:
/// ```zig
/// const patterns = &[_][]const u8{ "test_*", "*.zig" };
/// matchAll(patterns, "test_foo.zig") // returns true
/// matchAll(patterns, "test_foo.py")  // returns false
/// matchAll(patterns, "foo.zig")      // returns false
/// ```
///
pub fn matchAll(patterns: []const []const u8, text: []const u8) bool {
    for (patterns) |pattern| {
        if (!match(pattern, text)) return false;
    }
    return true;
}

/// Match a character class (e.g., '0-9', 'a-z') against a target character.
///
/// Returns `true` if the character is in the class, otherwise `false`.
///
fn matchCharacterClass(chars: []const u8, target: u8) bool {
    var i: usize = 0;
    while (i < chars.len) {
        // Check for range pattern (e.g., '0-9', 'a-z')
        if (i + 2 < chars.len and chars[i + 1] == '-') {
            const start = chars[i];
            const end = chars[i + 2];
            if (target >= start and target <= end) return true;
            i += 3;
        } else {
            if (chars[i] == target) return true;
            i += 1;
        }
    }
    return false;
}

// ============================================================================
// Tests
// ============================================================================

test "validate - valid patterns" {
    try validate("");
    try validate("*.zig");
    try validate("test_??.c");
    try validate("[a-z]*");
    try validate("\\*literal\\?");
    try validate("![abc]");
}

test "validate - unclosed bracket" {
    try expectError(error.UnclosedBracket, validate("[abc"));
    try expectError(error.UnclosedBracket, validate("test["));
    try expectError(error.UnclosedBracket, validate("test[a-z"));
}

test "validate - empty bracket" {
    try expectError(error.EmptyBracket, validate("[]"));
    try expectError(error.EmptyBracket, validate("test[]"));
}

test "validate - trailing backslash" {
    try expectError(error.TrailingBackslash, validate("\\"));
    try expectError(error.TrailingBackslash, validate("test\\"));
}

test "negation - basic" {
    try expect(match("!*.tmp", "file.txt"));
    try expect(!match("!*.tmp", "file.tmp"));
    try expect(match("!test*", "production"));
    try expect(!match("!test*", "test_file"));
}

test "negation - with wildcards" {
    try expect(!match("!a*c", "abc"));
    try expect(match("!a*c", "abd"));
    try expect(!match("!?at", "cat"));
    try expect(match("!?at", "cats"));
}

test "negation - with character classes" {
    try expect(!match("![0-9]", "5"));
    try expect(match("![0-9]", "a"));
    try expect(!match("!Letter[0-9]", "Letter5"));
    try expect(match("!Letter[0-9]", "Letter"));
}

test "matchMultiple - basic" {
    const patterns = &[_][]const u8{ "*.zig", "*.c", "*.h" };

    try expect(matchMultiple(patterns, "main.zig"));
    try expect(matchMultiple(patterns, "test.c"));
    try expect(matchMultiple(patterns, "header.h"));
    try expect(!matchMultiple(patterns, "script.py"));
    try expect(!matchMultiple(patterns, "README.md"));
}

test "matchMultiple - with negation" {
    const patterns = &[_][]const u8{ "*.txt", "!test_*" };

    try expect(matchMultiple(patterns, "file.txt"));
    try expect(matchMultiple(patterns, "production.log"));
    try expect(matchMultiple(patterns, "test_file.txt")); // matches *.txt
}

test "matchMultiple - empty patterns" {
    const patterns = &[_][]const u8{};
    try expect(!matchMultiple(patterns, "anything"));
}

test "matchAny - same as matchMultiple" {
    const patterns = &[_][]const u8{ "test_*", "*_test" };

    try expect(matchAny(patterns, "test_file"));
    try expect(matchAny(patterns, "file_test"));
    try expect(!matchAny(patterns, "production"));
}

test "matchAll - basic" {
    const patterns = &[_][]const u8{ "test_*", "*.zig" };

    try expect(matchAll(patterns, "test_main.zig"));
    try expect(!matchAll(patterns, "test_main.c"));
    try expect(!matchAll(patterns, "main.zig"));
    try expect(!matchAll(patterns, "production.rs"));
}

test "matchAll - single pattern" {
    const patterns = &[_][]const u8{"*.txt"};

    try expect(matchAll(patterns, "file.txt"));
    try expect(!matchAll(patterns, "file.md"));
}

test "matchAll - empty patterns" {
    const patterns = &[_][]const u8{};
    try expect(matchAll(patterns, "anything")); // vacuous truth
}

test "matchAll - with wildcards" {
    const patterns = &[_][]const u8{ "src/*", "*.zig", "*main*" };

    try expect(matchAll(patterns, "src/main.zig"));
    try expect(!matchAll(patterns, "src/test.zig"));
    try expect(!matchAll(patterns, "lib/main.zig"));
}

test "matchAll - with negation" {
    const patterns = &[_][]const u8{ "*.txt", "!test_*" };

    try expect(matchAll(patterns, "file.txt"));
    try expect(!matchAll(patterns, "test_file.txt"));
    try expect(!matchAll(patterns, "test_file.md"));
}

test "empty strings" {
    try expect(match("", ""));
    try expect(!match("", "a"));
    try expect(!match("a", ""));
}

test "single character matches" {
    try expect(match("a", "a"));
    try expect(!match("a", "b"));
    try expect(match("abc", "abc"));
    try expect(!match("abc", "abd"));
}

test "question mark wildcard" {
    try expect(match("?", "a"));
    try expect(match("a?", "ab"));
    try expect(match("?b", "ab"));
    try expect(match("a?c", "abc"));
    try expect(!match("?", ""));
    try expect(!match("", "?"));
    try expect(!match("??", "a"));
    try expect(match("??", "ab"));
}

test "asterisk wildcard" {
    try expect(match("*", ""));
    try expect(match("*", "abc"));
    try expect(match("a*", "a"));
    try expect(match("a*", "abc"));
    try expect(match("*c", "abc"));
    try expect(match("a*c", "abc"));
    try expect(match("a*c", "ac"));
    try expect(match("a*c", "abbc"));
    try expect(!match("a*c", "abd"));
    try expect(match("*a*", "aaa"));
    try expect(match("*", "anystring"));
    try expect(match("*.zig", "main.zig"));
    try expect(match("src/*.zig", "src/main.zig"));
    try expect(!match("src/*.zig", "main.zig"));
}

test "character class" {
    try expect(match("[abc]", "a"));
    try expect(match("[abc]", "b"));
    try expect(match("[abc]", "c"));
    try expect(!match("[abc]", "d"));
    try expect(match("a[bc]", "ab"));
    try expect(match("a[bc]", "ac"));
    try expect(!match("a[bc]", "ad"));
    try expect(match("[CB]at", "Cat"));
    try expect(match("[CB]at", "Bat"));
    try expect(!match("[CB]at", "cat"));
    try expect(!match("[CB]at", "bat"));
    try expect(!match("[CB]at", "CBat"));
}

test "complex patterns" {
    try expect(match("test_*.zig", "test_foo.zig"));
    try expect(match("*/*.zig", "src/main.zig"));
    try expect(match("?at", "Cat"));
    try expect(match("?at", "Bat"));
    try expect(!match("?at", "at"));
    try expect(match("Law*", "Law"));
    try expect(match("Law*", "Laws"));
    try expect(match("Law*", "Lawyer"));
    try expect(!match("Law*", "GrokLaw"));
    try expect(!match("Law*", "La"));
    try expect(!match("Law*", "aw"));
    try expect(match("Letter[0-9]", "Letter0"));
    try expect(match("Letter[0-9]", "Letter5"));
    try expect(match("Letter[0-9]", "Letter9"));
    try expect(!match("Letter[0-9]", "Letter"));
    try expect(!match("Letter[0-9]", "Letters"));
    try expect(!match("Letter[0-9]", "Letter10"));
}

test "edge cases and robustness" {
    // Pattern longer than text
    try expect(!match("abc", "ab"));
    // Text longer than pattern
    try expect(!match("ab", "abc"));
    // Multiple wildcards
    try expect(match("?*?", "abc"));
    try expect(match("*?*", "abc"));
    try expect(match("*?*?", "abcd"));
    // Invalid brackets
    try expect(!match("[", "a"));
    try expect(!match("[a", "a"));
    try expect(!match("[]", "a"));
    // Special characters as literals
    try expect(match("\\*", "*"));
    try expect(!match("\\*", "a"));
    // Case sensitivity
    try expect(!match("A", "a"));
    try expect(match("a", "a"));
    // Long strings
    const long_pattern = "a" ** 1000;
    const long_text = "a" ** 1000;
    try expect(match(long_pattern, long_text));
    try expect(!match(long_pattern, long_text ++ "b"));
}
