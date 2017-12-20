# philiprehberger-sanitize_html

[![Tests](https://github.com/philiprehberger/rb-sanitize-html/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-sanitize-html/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-sanitize_html.svg)](https://rubygems.org/gems/philiprehberger-sanitize_html)
[![License](https://img.shields.io/github/license/philiprehberger/rb-sanitize-html)](LICENSE)
[![Sponsor](https://img.shields.io/badge/sponsor-GitHub%20Sponsors-ec6cb9)](https://github.com/sponsors/philiprehberger)

HTML sanitizer with configurable allow lists for safe user content rendering

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-sanitize_html"
```

Or install directly:

```bash
gem install philiprehberger-sanitize_html
```

## Usage

```ruby
require "philiprehberger/sanitize_html"

# Clean HTML with default allowed tags
safe = Philiprehberger::SanitizeHtml.clean('<p>Hello <script>alert("xss")</script></p>')
# => "<p>Hello </p>"
```

### Custom Allow Lists

```ruby
Philiprehberger::SanitizeHtml.clean(
  '<div class="box"><span>text</span></div>',
  tags: %w[div span],
  attributes: { 'div' => %w[class] }
)
# => '<div class="box"><span>text</span></div>'
```

### Strip All Tags

```ruby
Philiprehberger::SanitizeHtml.strip('<p>Hello <strong>world</strong></p>')
# => "Hello world"
```

### Escape HTML

```ruby
Philiprehberger::SanitizeHtml.escape('<p>Hello</p>')
# => "&lt;p&gt;Hello&lt;/p&gt;"
```

## API

| Method / Constant | Description |
|--------------------|-------------|
| `.clean(html, tags:, attributes:)` | Sanitize HTML keeping only allowed tags and attributes |
| `.strip(html)` | Remove all HTML tags, returning plain text |
| `.escape(html)` | Entity-encode all HTML special characters |
| `DEFAULT_ALLOWED_TAGS` | Frozen array of tag names allowed by default (`p`, `br`, `strong`, `em`, `b`, `i`, `u`, `a`, `ul`, `ol`, `li`, `blockquote`, `code`, `pre`, `h1`-`h6`) |
| `DEFAULT_ALLOWED_ATTRIBUTES` | Frozen hash of attributes allowed per tag (`a` => `href`, `title`; `img` => `src`, `alt`) |
| `DANGEROUS_TAGS` | Frozen array of tags always removed with their content (`script`, `style`, `iframe`) |
| `EVENT_ATTRIBUTE_PATTERN` | Regex matching event-handler attributes (e.g. `onclick`, `onload`) that are always stripped |
| `Error` | Base error class for the module (`Philiprehberger::SanitizeHtml::Error`) |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

[MIT](LICENSE)
