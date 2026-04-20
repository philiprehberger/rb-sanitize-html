# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::SanitizeHtml do
  describe 'VERSION' do
    it 'has a version number' do
      expect(Philiprehberger::SanitizeHtml::VERSION).not_to be_nil
    end
  end

  describe '.clean' do
    it 'returns empty string for nil' do
      expect(described_class.clean(nil)).to eq('')
    end

    it 'returns empty string for empty string' do
      expect(described_class.clean('')).to eq('')
    end

    it 'keeps allowed tags' do
      html = '<p>Hello <strong>world</strong></p>'
      expect(described_class.clean(html)).to eq('<p>Hello <strong>world</strong></p>')
    end

    it 'removes disallowed tags' do
      html = '<p>Hello</p><div>world</div>'
      expect(described_class.clean(html)).to eq('<p>Hello</p>world')
    end

    it 'removes script tags and their content' do
      html = '<p>Safe</p><script>alert("xss")</script>'
      expect(described_class.clean(html)).to eq('<p>Safe</p>')
    end

    it 'removes style tags and their content' do
      html = '<p>Text</p><style>body { color: red; }</style>'
      expect(described_class.clean(html)).to eq('<p>Text</p>')
    end

    it 'removes iframe tags and their content' do
      html = '<p>Text</p><iframe src="evil.com"></iframe>'
      expect(described_class.clean(html)).to eq('<p>Text</p>')
    end

    it 'strips event attributes' do
      html = '<a href="http://example.com" onclick="alert(1)">click</a>'
      expect(described_class.clean(html)).to eq('<a href="http://example.com">click</a>')
    end

    it 'allows href and title on a tags' do
      html = '<a href="http://example.com" title="Example">link</a>'
      expect(described_class.clean(html)).to eq('<a href="http://example.com" title="Example">link</a>')
    end

    it 'strips disallowed attributes' do
      html = '<a href="http://example.com" class="red">link</a>'
      expect(described_class.clean(html)).to eq('<a href="http://example.com">link</a>')
    end

    it 'allows custom tag list' do
      html = '<div>Hello</div><span>world</span>'
      expect(described_class.clean(html, tags: %w[div])).to eq('<div>Hello</div>world')
    end

    it 'allows custom attribute list' do
      html = '<a href="x" class="y">link</a>'
      result = described_class.clean(html, attributes: { 'a' => %w[href class] })
      expect(result).to eq('<a href="x" class="y">link</a>')
    end

    it 'keeps heading tags h1 through h6' do
      html = '<h1>Title</h1><h3>Subtitle</h3>'
      expect(described_class.clean(html)).to eq('<h1>Title</h1><h3>Subtitle</h3>')
    end

    it 'keeps list tags' do
      html = '<ul><li>Item</li></ul>'
      expect(described_class.clean(html)).to eq('<ul><li>Item</li></ul>')
    end

    it 'keeps blockquote and code tags' do
      html = '<blockquote><code>x</code></blockquote>'
      expect(described_class.clean(html)).to eq('<blockquote><code>x</code></blockquote>')
    end

    it 'keeps pre tags' do
      html = '<pre>code block</pre>'
      expect(described_class.clean(html)).to eq('<pre>code block</pre>')
    end

    it 'escapes attribute values' do
      html = '<a href="x&amp;y">link</a>'
      result = described_class.clean(html)
      expect(result).to include('href=')
    end
  end

  describe '.clean with profiles' do
    context ':strict profile' do
      it 'removes all tags' do
        html = '<p>Hello <strong>world</strong></p>'
        expect(described_class.clean(html, profile: :strict)).to eq('Hello world')
      end

      it 'removes all attributes' do
        html = '<a href="http://example.com">link</a>'
        expect(described_class.clean(html, profile: :strict)).to eq('link')
      end
    end

    context ':moderate profile' do
      it 'allows basic formatting tags' do
        html = '<p>Hello <strong>world</strong></p>'
        expect(described_class.clean(html, profile: :moderate)).to eq('<p>Hello <strong>world</strong></p>')
      end

      it 'removes link tags' do
        html = '<a href="http://example.com">link</a>'
        expect(described_class.clean(html, profile: :moderate)).to eq('link')
      end

      it 'allows list tags' do
        html = '<ul><li>Item</li></ul>'
        expect(described_class.clean(html, profile: :moderate)).to eq('<ul><li>Item</li></ul>')
      end

      it 'removes heading tags' do
        html = '<h1>Title</h1>'
        expect(described_class.clean(html, profile: :moderate)).to eq('Title')
      end
    end

    context ':permissive profile' do
      it 'allows div and span tags' do
        html = '<div><span>text</span></div>'
        expect(described_class.clean(html, profile: :permissive)).to eq('<div><span>text</span></div>')
      end

      it 'allows table tags' do
        html = '<table><tr><td>cell</td></tr></table>'
        expect(described_class.clean(html, profile: :permissive)).to eq('<table><tr><td>cell</td></tr></table>')
      end

      it 'allows img tags with src and alt' do
        html = '<img src="image.png" alt="photo" />'
        result = described_class.clean(html, profile: :permissive)
        expect(result).to include('src="image.png"')
        expect(result).to include('alt="photo"')
      end

      it 'allows hr and sub/sup tags' do
        html = '<hr /><sub>sub</sub><sup>sup</sup>'
        result = described_class.clean(html, profile: :permissive)
        expect(result).to include('<sub>sub</sub>')
        expect(result).to include('<sup>sup</sup>')
      end

      it 'still removes script tags' do
        html = '<div>Safe</div><script>alert(1)</script>'
        expect(described_class.clean(html, profile: :permissive)).to eq('<div>Safe</div>')
      end
    end

    context ':markdown profile' do
      it 'allows code and pre tags' do
        html = '<pre><code>puts "hello"</code></pre>'
        expect(described_class.clean(html, profile: :markdown)).to eq('<pre><code>puts "hello"</code></pre>')
      end

      it 'allows links with href' do
        html = '<a href="http://example.com">link</a>'
        expect(described_class.clean(html, profile: :markdown)).to eq('<a href="http://example.com">link</a>')
      end

      it 'allows heading tags' do
        html = '<h1>Title</h1><h2>Subtitle</h2>'
        expect(described_class.clean(html, profile: :markdown)).to eq('<h1>Title</h1><h2>Subtitle</h2>')
      end

      it 'allows table tags' do
        html = '<table><thead><tr><th>Header</th></tr></thead><tbody><tr><td>Cell</td></tr></tbody></table>'
        result = described_class.clean(html, profile: :markdown)
        expect(result).to include('<table>')
        expect(result).to include('<th>Header</th>')
        expect(result).to include('<td>Cell</td>')
      end
    end

    it 'raises error for unknown profile' do
      expect { described_class.clean('<p>test</p>', profile: :unknown) }
        .to raise_error(Philiprehberger::SanitizeHtml::Error, /Unknown profile/)
    end

    it 'allows overriding tags with profile' do
      html = '<p>Hello</p><div>world</div>'
      result = described_class.clean(html, profile: :strict, tags: %w[p])
      expect(result).to eq('<p>Hello</p>world')
    end
  end

  describe '.clean with URL protocol sanitization' do
    it 'allows http URLs by default' do
      html = '<a href="http://example.com">link</a>'
      expect(described_class.clean(html)).to include('href="http://example.com"')
    end

    it 'allows https URLs by default' do
      html = '<a href="https://example.com">link</a>'
      expect(described_class.clean(html)).to include('href="https://example.com"')
    end

    it 'allows mailto URLs by default' do
      html = '<a href="mailto:test@example.com">email</a>'
      expect(described_class.clean(html)).to include('href="mailto:test@example.com"')
    end

    it 'blocks javascript: URLs' do
      html = '<a href="javascript:alert(1)">link</a>'
      expect(described_class.clean(html)).to eq('<a>link</a>')
    end

    it 'blocks data: URLs by default' do
      html = '<a href="data:text/html,<script>alert(1)</script>">link</a>'
      result = described_class.clean(html)
      expect(result).not_to include('data:')
    end

    it 'allows custom protocols' do
      html = '<a href="ftp://files.example.com/doc.pdf">download</a>'
      result = described_class.clean(html, allowed_protocols: %w[http https ftp])
      expect(result).to include('href="ftp://files.example.com/doc.pdf"')
    end

    it 'blocks protocols not in allowed list' do
      html = '<a href="ftp://files.example.com/doc.pdf">download</a>'
      result = described_class.clean(html, allowed_protocols: %w[http https])
      expect(result).to eq('<a>download</a>')
    end

    it 'allows relative URLs' do
      html = '<a href="/page">link</a>'
      expect(described_class.clean(html)).to include('href="/page"')
    end

    it 'allows fragment URLs' do
      html = '<a href="#section">link</a>'
      expect(described_class.clean(html)).to include('href="#section"')
    end

    it 'allows query-only URLs' do
      html = '<a href="?page=2">link</a>'
      expect(described_class.clean(html)).to include('href="?page=2"')
    end
  end

  describe '.clean with data URI filtering' do
    it 'blocks all data URIs by default' do
      html = '<a href="data:image/png;base64,abc123">img</a>'
      result = described_class.clean(html)
      expect(result).to eq('<a>img</a>')
    end

    it 'allows data URIs with permitted MIME types' do
      html = '<a href="data:image/png;base64,abc123">img</a>'
      result = described_class.clean(html, allowed_data_mimes: ['image/png'])
      expect(result).to include('data:image/png')
    end

    it 'blocks data URIs with disallowed MIME types' do
      html = '<a href="data:text/html,<script>alert(1)</script>">xss</a>'
      result = described_class.clean(html, allowed_data_mimes: ['image/png', 'image/jpeg'])
      expect(result).to eq('<a>xss</a>')
    end

    it 'allows multiple MIME types' do
      html_png = '<a href="data:image/png;base64,abc">png</a>'
      html_jpg = '<a href="data:image/jpeg;base64,xyz">jpg</a>'
      mimes = ['image/png', 'image/jpeg']

      expect(described_class.clean(html_png, allowed_data_mimes: mimes)).to include('data:image/png')
      expect(described_class.clean(html_jpg, allowed_data_mimes: mimes)).to include('data:image/jpeg')
    end

    it 'handles data URI with no MIME type' do
      html = '<a href="data:,Hello">test</a>'
      result = described_class.clean(html, allowed_data_mimes: ['image/png'])
      expect(result).to eq('<a>test</a>')
    end

    it 'is case insensitive for data URI scheme' do
      html = '<a href="DATA:image/png;base64,abc">img</a>'
      result = described_class.clean(html, allowed_data_mimes: ['image/png'])
      expect(result).to include('image/png')
    end
  end

  describe '.clean with CSS sanitization' do
    it 'allows safe CSS properties in style attributes' do
      html = '<p style="color: red; font-size: 14px">text</p>'
      result = described_class.clean(html, tags: %w[p], attributes: { 'p' => %w[style] })
      expect(result).to include('color: red')
      expect(result).to include('font-size: 14px')
    end

    it 'strips dangerous CSS expression()' do
      html = '<p style="width: expression(alert(1))">text</p>'
      result = described_class.clean(html, tags: %w[p], attributes: { 'p' => %w[style] })
      expect(result).to eq('<p>text</p>')
    end

    it 'strips CSS with javascript: in url()' do
      html = '<p style="background: url(javascript:alert(1))">text</p>'
      result = described_class.clean(html, tags: %w[p], attributes: { 'p' => %w[style] })
      expect(result).to eq('<p>text</p>')
    end

    it 'strips unknown CSS properties' do
      html = '<p style="color: red; -moz-binding: url(evil)">text</p>'
      result = described_class.clean(html, tags: %w[p], attributes: { 'p' => %w[style] })
      expect(result).to include('color: red')
      expect(result).not_to include('-moz-binding')
    end

    it 'allows margin and padding properties' do
      html = '<p style="margin: 10px; padding: 5px">text</p>'
      result = described_class.clean(html, tags: %w[p], attributes: { 'p' => %w[style] })
      expect(result).to include('margin: 10px')
      expect(result).to include('padding: 5px')
    end

    it 'allows border properties' do
      html = '<p style="border: 1px solid black; border-radius: 4px">text</p>'
      result = described_class.clean(html, tags: %w[p], attributes: { 'p' => %w[style] })
      expect(result).to include('border: 1px solid black')
      expect(result).to include('border-radius: 4px')
    end

    it 'allows text properties' do
      html = '<p style="text-align: center; text-decoration: underline">text</p>'
      result = described_class.clean(html, tags: %w[p], attributes: { 'p' => %w[style] })
      expect(result).to include('text-align: center')
      expect(result).to include('text-decoration: underline')
    end

    it 'produces empty style when all properties are stripped' do
      html = '<p style="position: absolute; z-index: 999">text</p>'
      result = described_class.clean(html, tags: %w[p], attributes: { 'p' => %w[style] })
      expect(result).to eq('<p>text</p>')
    end
  end

  describe '.clean with entity normalization' do
    it 'decodes hex-encoded HTML entities before sanitization' do
      # &#x3C; = < and &#x3E; = >
      html = '&#x3C;script&#x3E;alert(1)&#x3C;/script&#x3E;'
      result = described_class.clean(html)
      expect(result).not_to include('alert')
    end

    it 'decodes decimal-encoded HTML entities before sanitization' do
      # &#60; = < and &#62; = >
      html = '&#60;script&#62;alert(1)&#60;/script&#62;'
      result = described_class.clean(html)
      expect(result).not_to include('alert')
    end

    it 'prevents double-encoded bypasses' do
      html = '&#x3C;iframe src="evil.com"&#x3E;&#x3C;/iframe&#x3E;'
      result = described_class.clean(html)
      expect(result).not_to include('iframe')
      expect(result).not_to include('evil.com')
    end

    it 'handles mixed encoding' do
      html = '<p>Safe</p>&#60;script&#62;alert(1)&#x3C;/script&#x3E;'
      result = described_class.clean(html)
      expect(result).to include('<p>Safe</p>')
      expect(result).not_to include('alert')
    end

    it 'preserves normal text with entity normalization' do
      html = '<p>Hello &amp; world</p>'
      result = described_class.clean(html)
      expect(result).to include('Hello')
      expect(result).to include('world')
    end
  end

  describe '.clean with callback hooks' do
    it 'calls on_tag callback for each tag' do
      tags_seen = []
      html = '<p>Hello</p><strong>world</strong>'
      described_class.clean(html, on_tag: lambda { |tag, _attrs|
  tags_seen << tag
  {}
})
      expect(tags_seen).to include('p', 'strong')
    end

    it 'removes tag when callback returns nil' do
      html = '<p>Keep</p><strong>Remove</strong>'
      result = described_class.clean(html, on_tag: lambda { |tag, _attrs|
        tag == 'strong' ? nil : {}
      })
      expect(result).to include('<p>Keep</p>')
      expect(result).not_to include('<strong>')
    end

    it 'allows modifying attributes via callback' do
      html = '<a href="http://example.com">link</a>'
      result = described_class.clean(html, on_tag: lambda { |_tag, attrs|
        attrs['title'] = 'Added by callback'
        attrs
      })
      expect(result).to include('title="Added by callback"')
    end

    it 'receives attributes hash in callback' do
      received_attrs = nil
      html = '<a href="http://example.com" title="Test">link</a>'
      described_class.clean(html, on_tag: lambda { |_tag, attrs|
        received_attrs = attrs
        attrs
      })
      expect(received_attrs).to include('href' => 'http://example.com', 'title' => 'Test')
    end

    it 'still enforces allowed attributes after callback' do
      html = '<a href="http://example.com">link</a>'
      result = described_class.clean(html, on_tag: lambda { |_tag, attrs|
        attrs['onclick'] = 'alert(1)'
        attrs
      })
      expect(result).not_to include('onclick')
    end

    it 'works without callback (nil)' do
      html = '<p>Hello</p>'
      result = described_class.clean(html, on_tag: nil)
      expect(result).to eq('<p>Hello</p>')
    end
  end

  describe '.strip' do
    it 'returns empty string for nil' do
      expect(described_class.strip(nil)).to eq('')
    end

    it 'returns empty string for empty string' do
      expect(described_class.strip('')).to eq('')
    end

    it 'removes all HTML tags' do
      html = '<p>Hello <strong>world</strong></p>'
      expect(described_class.strip(html)).to eq('Hello world')
    end

    it 'removes script tags and their content' do
      html = 'Safe<script>alert("xss")</script> text'
      expect(described_class.strip(html)).to eq('Safe text')
    end

    it 'removes style tags and their content' do
      html = 'Text<style>.x{}</style> here'
      expect(described_class.strip(html)).to eq('Text here')
    end

    it 'decodes HTML entities' do
      html = '&amp; &lt; &gt;'
      expect(described_class.strip(html)).to eq('& < >')
    end

    it 'handles nested tags' do
      html = '<div><p>Hello <em>world</em></p></div>'
      expect(described_class.strip(html)).to eq('Hello world')
    end

    it 'normalizes encoded entities before stripping' do
      html = '&#x3C;script&#x3E;alert(1)&#x3C;/script&#x3E;'
      result = described_class.strip(html)
      expect(result).not_to include('alert')
    end
  end

  describe '.escape' do
    it 'returns empty string for nil' do
      expect(described_class.escape(nil)).to eq('')
    end

    it 'returns empty string for empty string' do
      expect(described_class.escape('')).to eq('')
    end

    it 'escapes angle brackets' do
      expect(described_class.escape('<p>Hello</p>')).to eq('&lt;p&gt;Hello&lt;/p&gt;')
    end

    it 'escapes ampersands' do
      expect(described_class.escape('a & b')).to eq('a &amp; b')
    end

    it 'escapes double quotes' do
      expect(described_class.escape('a "b" c')).to eq('a &quot;b&quot; c')
    end

    it 'escapes single quotes' do
      expect(described_class.escape("a 'b' c")).to eq('a &#39;b&#39; c')
    end

    it 'escapes all special characters together' do
      expect(described_class.escape('<a href="x">')).to eq('&lt;a href=&quot;x&quot;&gt;')
    end

    it 'leaves plain text unchanged' do
      expect(described_class.escape('Hello world')).to eq('Hello world')
    end
  end

  describe '.sanitize_url' do
    it 'passes http URLs through' do
      expect(described_class.sanitize_url('https://example.com/path')).to eq('https://example.com/path')
    end

    it 'trims leading/trailing whitespace' do
      expect(described_class.sanitize_url('  https://example.com  ')).to eq('https://example.com')
    end

    it 'returns nil for disallowed protocols' do
      expect(described_class.sanitize_url('javascript:alert(1)')).to be_nil
    end

    it 'allows fragment-only URLs' do
      expect(described_class.sanitize_url('#section')).to eq('#section')
    end

    it 'allows relative paths' do
      expect(described_class.sanitize_url('/profile')).to eq('/profile')
    end

    it 'allows custom protocol lists' do
      expect(described_class.sanitize_url('ftp://files.example.com', allowed_protocols: %w[ftp])).to eq('ftp://files.example.com')
    end

    it 'rejects data: URIs by default' do
      expect(described_class.sanitize_url('data:text/html,<script>')).to be_nil
    end

    it 'accepts allow-listed data: MIME types' do
      expect(described_class.sanitize_url('data:image/png;base64,AAA',
                                          allowed_data_mimes: %w[image/png])).to eq('data:image/png;base64,AAA')
    end

    it 'returns nil for an empty string' do
      expect(described_class.sanitize_url('   ')).to be_nil
    end

    it 'returns nil for nil input' do
      expect(described_class.sanitize_url(nil)).to be_nil
    end
  end

  describe 'constants' do
    it 'has SAFE_CSS_PROPERTIES frozen' do
      expect(described_class::SAFE_CSS_PROPERTIES).to be_frozen
    end

    it 'has PROFILES frozen' do
      expect(described_class::PROFILES).to be_frozen
    end

    it 'has DEFAULT_ALLOWED_PROTOCOLS frozen' do
      expect(described_class::DEFAULT_ALLOWED_PROTOCOLS).to be_frozen
    end

    it 'has DEFAULT_ALLOWED_DATA_MIMES frozen' do
      expect(described_class::DEFAULT_ALLOWED_DATA_MIMES).to be_frozen
    end

    it 'has five profiles defined' do
      expect(described_class::PROFILES.keys).to contain_exactly(:strict, :moderate, :permissive, :markdown, :text_only)
    end
  end

  describe '.strip_tags' do
    it 'strips a simple tag and keeps inner text' do
      expect(described_class.strip_tags('<b>hi</b>')).to eq('hi')
    end

    it 'strips nested tags' do
      html = '<div><p>Hello <em>world</em></p></div>'
      expect(described_class.strip_tags(html)).to eq('Hello world')
    end

    it 'removes script tags and their content entirely' do
      result = described_class.strip_tags('<script>alert(1)</script>')
      expect(result).to eq('')
      expect(result).not_to include('alert')
    end

    it 'removes style tags and their content entirely' do
      result = described_class.strip_tags('<style>body{}</style>')
      expect(result).to eq('')
      expect(result).not_to include('body')
    end

    it 'decodes &amp; to &' do
      expect(described_class.strip_tags('Tom &amp; Jerry')).to eq('Tom & Jerry')
    end

    it "decodes &#39; to '" do
      expect(described_class.strip_tags('it&#39;s')).to eq("it's")
    end

    it 'returns empty string for nil' do
      expect(described_class.strip_tags(nil)).to eq('')
    end

    it 'returns empty string for empty string' do
      expect(described_class.strip_tags('')).to eq('')
    end
  end

  describe '.clean with :text_only profile' do
    it 'matches strip_tags for simple tags' do
      html = '<b>hi</b>'
      expect(described_class.clean(html, profile: :text_only)).to eq(described_class.strip_tags(html))
    end

    it 'matches strip_tags for nested tags with entities' do
      html = '<p>Tom &amp; <em>Jerry</em></p>'
      expect(described_class.clean(html, profile: :text_only)).to eq(described_class.strip_tags(html))
    end

    it 'matches strip_tags when removing script content' do
      html = 'Hi<script>alert(1)</script> there'
      expect(described_class.clean(html, profile: :text_only)).to eq(described_class.strip_tags(html))
    end

    it 'matches strip_tags for nil input' do
      expect(described_class.clean(nil, profile: :text_only)).to eq(described_class.strip_tags(nil))
    end
  end
end
