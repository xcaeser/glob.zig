# Release Notes

## v0.2.0

v0.2.0 makes matching safer, faster on hostile wildcard patterns, and easier to
configure while keeping the library allocation-free and dependency-free.

- Replaced recursive `*` matching with constant-stack iterative backtracking,
  bounding worst-case work to `O(pattern.len * text.len)`.
- Added negated and escaped character classes.
- Added pathname, leading-period, no-escape, and ASCII case-insensitive options.
- Invalid configurable patterns now return `ValidationError`.
- Reduced the API to `match`, `matchWithOptions`, `validate`, `matchAny`, and
  `matchAll`.

### Breaking changes from v0.1.0

- Requires Zig `0.17.0-dev.1893+78e3b1c73`.
- Removed `matchMultiple`; use `matchAny`.
- Added `ValidationError.InvalidRange`; reversed ranges such as `[z-a]` now fail
  validation.
- Leading `!` or `^` inside a character class now negates the class.
- Invalid patterns always return `false` from `match`, including negated ones.

Verified by 26 tests in Debug and ReleaseFast modes.

## v0.1.0 (Initial Release)

- Initial implementation of glob pattern matching
- Support for wildcards: `*` (any characters), `?` (single character)
- Character classes: `[abc]` (set), `[a-z]` (range)
- Negation with `!` prefix
- Pattern validation for syntax errors
- Multiple pattern matching: `matchAny` (any match), `matchAll` (all match)
- Pure Zig implementation with no dependencies
- Comprehensive test suite covering all features
