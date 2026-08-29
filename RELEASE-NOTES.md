# Release Notes

## v0.2.0

- Replaced recursive `*` matching with a constant-stack implementation
- Added negated and escaped character classes
- Added pathname, leading-period, no-escape, and ASCII case-insensitive options
- Made configurable matching report precise validation errors
- Reduced the public API to `match`, `matchWithOptions`, `validate`, `matchAny`, and `matchAll`

## v0.1.0 (Initial Release)

- Initial implementation of glob pattern matching
- Support for wildcards: `*` (any characters), `?` (single character)
- Character classes: `[abc]` (set), `[a-z]` (range)
- Negation with `!` prefix
- Pattern validation for syntax errors
- Multiple pattern matching: `matchAny` (any match), `matchAll` (all match)
- Pure Zig implementation with no dependencies
- Comprehensive test suite covering all features
