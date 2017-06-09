# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.4] - 2026-03-24

### Changed
- Expand README API table to document all public methods

## [0.1.3] - 2026-03-24

### Fixed
- Fix README one-liner to remove trailing period

## [0.1.2] - 2026-03-24

### Fixed
- Remove inline comments from Development section to match template

## [0.1.1] - 2026-03-22

### Changed
- Update rubocop configuration for Windows compatibility

## [0.1.0] - 2026-03-22

### Added
- Initial release
- HTML sanitization with configurable allow lists for tags and attributes
- Strip method to remove all HTML tags and return plain text
- Escape method to entity-encode all HTML tags
- Default allowed tags: p, br, strong, em, b, i, u, a, ul, ol, li, blockquote, code, pre, h1-h6
- Default allowed attributes: a (href, title), img (src, alt)
- Automatic removal of script, style, and iframe tags
- Automatic removal of event attributes (onclick, onload, etc.)
