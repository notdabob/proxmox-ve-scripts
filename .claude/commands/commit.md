# Smart Commit with Version Management

Execute the smart commit functionality that automatically handles version bumps and changelog updates.

This command provides smart commit functionality with automatic version management:

- Auto-detects commit type (patch/minor/major) from file changes
- Updates CHANGELOG.md with new version entry and proper formatting
- Creates properly formatted git commits with Claude Code attribution
- Uses CHANGELOG.md as the single source of truth for version tracking
- Generates unique changelog section headers to avoid MD024 linter conflicts

**Important**: Changelog sections use version-specific headers to prevent markdown linter conflicts:

- Use format like "### Added in v2.4.0" instead of just "### Added"
- Include version number and timestamp in section headers
- This prevents MD024/no-duplicate-heading errors across different versions

Version increment logic:

- **patch**: Bug fixes, documentation updates, small improvements
- **minor**: New features, script additions, significant enhancements
- **major**: Breaking changes, major architectural updates

The script intelligently determines whether changes warrant patch (bug fixes), minor (new features), or major (breaking changes) version increments based on the files modified.

When creating changelog entries, always use version-specific section headers like:

- "### Added in v2.4.0"
- "### Changed in v2.4.0"
- "### Removed in v2.4.0"
- "### Enhanced in v2.4.0"
