# Release Notes

## v0.1.0 (Initial Release)

- Initial implementation of glob pattern matching
- Support for wildcards: `*` (any characters), `?` (single character)
- Character classes: `[abc]` (set), `[a-z]` (range)
- Negation with `!` prefix
- Pattern validation for syntax errors
- Multiple pattern matching: `matchAny` (any match), `matchAll` (all match)
- Pure Zig implementation with no dependencies
- Comprehensive test suite covering all features