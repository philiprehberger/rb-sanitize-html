# frozen_string_literal: true

require_relative 'sanitize_html/version'

module Philiprehberger
  module SanitizeHtml
    class Error < StandardError; end

    DEFAULT_ALLOWED_TAGS = %w[
      p br strong em b i u a ul ol li blockquote code pre
      h1 h2 h3 h4 h5 h6
    ].freeze

    DEFAULT_ALLOWED_ATTRIBUTES = {
      'a' => %w[href title],
      'img' => %w[src alt]
    }.freeze

    DANGEROUS_TAGS = %w[script style iframe].freeze

    EVENT_ATTRIBUTE_PATTERN = /\A\s*on/i

    # Sanitize HTML by removing disallowed tags and attributes.
    #
    # @param html [String] the HTML string to sanitize
    # @param tags [Array<String>] allowed tag names
    # @param attributes [Hash{String => Array<String>}] allowed attributes per tag
    # @return [String] sanitized HTML
    def self.clean(html, tags: DEFAULT_ALLOWED_TAGS, attributes: DEFAULT_ALLOWED_ATTRIBUTES)
      return '' if html.nil? || html.empty?

      result = remove_dangerous_tags(html)
      process_tags(result, tags, attributes)
    end

    # Remove all HTML tags, returning only text content.
    #
    # @param html [String] the HTML string to strip
    # @return [String] plain text with no HTML tags
    def self.strip(html)
      return '' if html.nil? || html.empty?

      text = remove_dangerous_tags(html)
      text = text.gsub(/<[^>]*>/, '')
      decode_entities(text)
    end

    # Escape all HTML tags by converting < and > to entities.
    #
    # @param html [String] the HTML string to escape
    # @return [String] entity-encoded HTML
    def self.escape(html)
      return '' if html.nil? || html.empty?

      html.gsub('&', '&amp;')
          .gsub('<', '&lt;')
          .gsub('>', '&gt;')
          .gsub('"', '&quot;')
          .gsub("'", '&#39;')
    end

    # @api private
    def self.remove_dangerous_tags(html)
      result = html.dup
      DANGEROUS_TAGS.each do |tag|
        result = result.gsub(%r{<#{tag}[\s>].*?</#{tag}>}mi, '')
        result = result.gsub(%r{<#{tag}\s*/>}i, '')
      end
      result
    end

    # @api private
    def self.process_tags(html, allowed_tags, allowed_attributes)
      html.gsub(%r{<(/?)(\w+)([^>]*)(/?)>}) do |_match|
        closing = Regexp.last_match(1)
        tag = Regexp.last_match(2).downcase
        attrs = Regexp.last_match(3)
        self_closing = Regexp.last_match(4)

        next '' unless allowed_tags.include?(tag)

        clean_attrs = filter_attributes(tag, attrs, allowed_attributes)

        if closing == '/'
          "</#{tag}>"
        elsif clean_attrs.empty?
          "<#{tag}#{' /' unless self_closing.empty?}>"
        else
          "<#{tag} #{clean_attrs}#{' /' unless self_closing.empty?}>"
        end
      end
    end

    # @api private
    def self.filter_attributes(tag, attr_string, allowed_attributes)
      allowed = allowed_attributes.fetch(tag, [])
      return '' if allowed.empty?

      attrs = []
      attr_string.scan(/(\w[\w-]*)=(?:"([^"]*)"|'([^']*)'|(\S+))/) do |name, v1, v2, v3|
        attr_name = name.downcase
        next if EVENT_ATTRIBUTE_PATTERN.match?(attr_name)
        next unless allowed.include?(attr_name)

        value = v1 || v2 || v3
        attrs << "#{attr_name}=\"#{escape_attr(value)}\""
      end

      attrs.join(' ')
    end

    # @api private
    def self.escape_attr(value)
      value.to_s.gsub('&', '&amp;').gsub('"', '&quot;').gsub('<', '&lt;').gsub('>', '&gt;')
    end

    # @api private
    def self.decode_entities(text)
      text.gsub('&amp;', '&')
          .gsub('&lt;', '<')
          .gsub('&gt;', '>')
          .gsub('&quot;', '"')
          .gsub('&#39;', "'")
    end

    private_class_method :remove_dangerous_tags, :process_tags, :filter_attributes, :escape_attr, :decode_entities
  end
end
