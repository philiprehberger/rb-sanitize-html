# philiprehberger-sanitize_html

[![Tests](https://github.com/philiprehberger/rb-sanitize-html/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-sanitize-html/actions/workflows/ci.yml) [![Gem Version](https://img.shields.io/gem/v/philiprehberger-sanitize_html)](https://rubygems.org/gems/philiprehberger-sanitize_html) [![GitHub release](https://img.shields.io/github/v/release/philiprehberger/rb-sanitize-html)](https://github.com/philiprehberger/rb-sanitize-html/releases) [![GitHub last commit](https://img.shields.io/github/last-commit/philiprehberger/rb-sanitize-html)](https://github.com/philiprehberger/rb-sanitize-html/commits/main) [![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE) [![Bug Reports](https://img.shields.io/badge/bug-reports-red.svg)](https://github.com/philiprehberger/rb-sanitize-html/issues) [![Feature Requests](https://img.shields.io/badge/feature-requests-blue.svg)](https://github.com/philiprehberger/rb-sanitize-html/issues) [![GitHub Sponsors](https://img.shields.io/badge/sponsor-philiprehberger-ea4aaa.svg?logo=github)](https://github.com/sponsors/philiprehberger)

HTML sanitizer with configurable allow lists, security profiles, and URL/CSS sanitization for safe user content rendering

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

### Security Profiles

```ruby
# :strict - removes all tags
Philiprehberger::SanitizeHtml.clean('<p>Hello <b>world</b></p>', profile: :strict)
# => "Hello world"

# :moderate - basic formatting (p, br, strong, em, b, i, u, lists, blockquote)
Philiprehberger::SanitizeHtml.clean('<p>Hello <b>world</b></p>', profile: :moderate)
# => "<p>Hello <b>world</b></p>"

# :permissive - most safe tags (formatting, links, images, tables, divs, spans)
Philiprehberger::SanitizeHtml.clean('<div><table><tr><td>cell</td></tr></table></div>', profile: :permissive)
# => "<div><table><tr><td>cell</td></tr></table></div>"

# :markdown - code, links, formatting, headings, tables
Philiprehberger::SanitizeHtml.clean('<pre><code>puts "hi"</code></pre>', profile: :markdown)
# => '<pre><code>puts "hi"</code></pre>'
```

### URL Protocol Sanitization

```ruby
# Default: allows http, https, mailto
Philiprehberger::SanitizeHtml.clean('<a href="javascript:alert(1)">click</a>')
# => "<a>click</a>"

# Custom allowed protocols
Philiprehberger::SanitizeHtml.clean(
  '<a href="ftp://files.example.com/doc.pdf">download</a>',
  allowed_protocols: %w[http https ftp]
)
# => '<a href="ftp://files.example.com/doc.pdf">download</a>'
```

### Data URI Filtering

```ruby
# Allow specific MIME types for data: URIs
Philiprehberger::SanitizeHtml.clean(
  '<a href="data:image/png;base64,abc123">image</a>',
  allowed_data_mimes: ['image/png', 'image/jpeg']
)
# => '<a href="data:image/png;base64,abc123">image</a>'
```

### CSS Sanitization

```ruby
# Safe CSS properties are preserved, dangerous ones are stripped
Philiprehberger::SanitizeHtml.clean(
  '<p style="color: red; expression(alert(1))">text</p>',
  tags: %w[p],
  attributes: { 'p' => %w[style] }
)
# => '<p style="color: red">text</p>'
```

### Callback Hooks

```ruby
# Custom tag processing with on_tag callback
result = Philiprehberger::SanitizeHtml.clean(
  '<a href="http://example.com">link</a>',
  on_tag: ->(tag, attrs) {
    attrs['rel'] = 'nofollow' if tag == 'a'
    attrs
  }
)

# Return nil from callback to remove a tag
result = Philiprehberger::SanitizeHtml.clean(
  '<p>Keep</p><strong>Remove</strong>',
  on_tag: ->(tag, _attrs) { tag == 'strong' ? nil : {} }
)
# => "<p>Keep</p>"
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
| `.clean(html, tags:, attributes:, profile:, allowed_protocols:, allowed_data_mimes:, on_tag:)` | Sanitize HTML keeping only allowed tags and attributes with optional security profile, URL sanitization, data URI filtering, and callback hooks |
| `.strip(html)` | Remove all HTML tags, returning plain text (with entity normalization) |
| `.escape(html)` | Entity-encode all HTML special characters |
| `DEFAULT_ALLOWED_TAGS` | Frozen array of tag names allowed by default (`p`, `br`, `strong`, `em`, `b`, `i`, `u`, `a`, `ul`, `ol`, `li`, `blockquote`, `code`, `pre`, `h1`-`h6`) |
| `DEFAULT_ALLOWED_ATTRIBUTES` | Frozen hash of attributes allowed per tag (`a` => `href`, `title`; `img` => `src`, `alt`) |
| `DEFAULT_ALLOWED_PROTOCOLS` | Frozen array of allowed URL protocols (`http`, `https`, `mailto`) |
| `DEFAULT_ALLOWED_DATA_MIMES` | Frozen empty array of allowed data URI MIME types (none by default) |
| `SAFE_CSS_PROPERTIES` | Frozen array of CSS property names considered safe for style attributes |
| `PROFILES` | Frozen hash of predefined security profiles (`:strict`, `:moderate`, `:permissive`, `:markdown`) |
| `DANGEROUS_TAGS` | Frozen array of tags always removed with their content (`script`, `style`, `iframe`) |
| `EVENT_ATTRIBUTE_PATTERN` | Regex matching event-handler attributes (e.g. `onclick`, `onload`) that are always stripped |
| `Error` | Base error class for the module (`Philiprehberger::SanitizeHtml::Error`) |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Philip%20Rehberger-blue?logo=linkedin)](https://linkedin.com/in/philiprehberger) [![More Packages](https://img.shields.io/badge/more-packages-blue.svg)](https://github.com/philiprehberger?tab=repositories)

## License

[MIT](LICENSE)
