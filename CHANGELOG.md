# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-03-28

### Added

- CSS property sanitization within `style` attributes - allows only safe CSS properties (color, font-size, margin, etc.) and strips dangerous values (expression, javascript: in url)
- Predefined security profiles via `profile:` parameter - `:strict` (no tags), `:moderate` (basic formatting), `:permissive` (most safe tags including tables and images), `:markdown` (code, links, formatting, tables)
- URL attribute sanitization via `allowed_protocols:` parameter - restricts href/src to allowed protocols (defaults to http, https, mailto)
- Data URI filtering via `allowed_data_mimes:` parameter - allow or deny data: URLs by MIME type (e.g., image/png, image/jpeg)
- HTML entity decoding normalization before sanitization to prevent encoded bypasses (hex &#x3C; and decimal &#60; entities)
- Callback hooks for custom tag/attribute processing via `on_tag:` parameter - receives tag name and attributes hash, return nil to remove tag or modified hash to alter attributes

## [0.1.5] - 2026-03-26

### Changed

- Add Sponsor badge and fix License link format in README

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
