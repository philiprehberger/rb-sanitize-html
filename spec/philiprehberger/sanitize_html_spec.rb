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
      html = '<a href="http://example.com" style="color:red">link</a>'
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
end
