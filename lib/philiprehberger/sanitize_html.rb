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

    DEFAULT_ALLOWED_PROTOCOLS = %w[http https mailto].freeze

    DEFAULT_ALLOWED_DATA_MIMES = [].freeze

    SAFE_CSS_PROPERTIES = %w[
      color background-color font-size font-family font-weight font-style
      text-align text-decoration text-indent text-transform
      line-height letter-spacing word-spacing
      margin margin-top margin-right margin-bottom margin-left
      padding padding-top padding-right padding-bottom padding-left
      border border-top border-right border-bottom border-left
      border-color border-style border-width border-radius
      width height max-width max-height min-width min-height
      display float clear vertical-align
      list-style list-style-type
      white-space overflow
      opacity visibility
    ].freeze

    DANGEROUS_CSS_PATTERN = /expression\s*\(|javascript\s*:|url\s*\(\s*['"]?\s*javascript\s*:/i

    PROFILES = {
      strict: {
        tags: [],
        attributes: {}
      },
      moderate: {
        tags: %w[p br strong em b i u ul ol li blockquote],
        attributes: {}
      },
      permissive: {
        tags: %w[
          p br strong em b i u a ul ol li blockquote code pre
          h1 h2 h3 h4 h5 h6 img div span table thead tbody tr th td
          dl dt dd sub sup hr
        ],
        attributes: {
          'a' => %w[href title],
          'img' => %w[src alt width height],
          'td' => %w[colspan rowspan],
          'th' => %w[colspan rowspan]
        }
      },
      markdown: {
        tags: %w[
          p br strong em b i u a ul ol li blockquote code pre
          h1 h2 h3 h4 h5 h6 img hr table thead tbody tr th td
        ],
        attributes: {
          'a' => %w[href title],
          'img' => %w[src alt]
        }
      },
      text_only: {
        tags: [],
        attributes: {}
      }
    }.freeze

    # Sanitize HTML by removing disallowed tags and attributes.
    #
    # @param html [String] the HTML string to sanitize
    # @param tags [Array<String>] allowed tag names
    # @param attributes [Hash{String => Array<String>}] allowed attributes per tag
    # @param profile [Symbol, nil] predefined security profile (:strict, :moderate, :permissive, :markdown, :text_only)
    # @param allowed_protocols [Array<String>, nil] allowed URL protocols for href/src attributes
    # @param allowed_data_mimes [Array<String>, nil] allowed MIME types for data: URIs
    # @param on_tag [Proc, nil] callback for custom tag processing, receives (tag_name, attributes_hash)
    # @return [String] sanitized HTML
    def self.clean(html, tags: nil, attributes: nil, profile: nil,
                   allowed_protocols: nil, allowed_data_mimes: nil, on_tag: nil)
      return '' if html.nil? || html.empty?

      if profile
        raise Error, "Unknown profile: #{profile}" unless PROFILES.key?(profile)

        return strip_tags(html) if profile == :text_only && tags.nil? && attributes.nil?

        profile_config = PROFILES[profile]
        tags ||= profile_config[:tags]
        attributes ||= profile_config[:attributes]
      end

      tags ||= DEFAULT_ALLOWED_TAGS
      attributes ||= DEFAULT_ALLOWED_ATTRIBUTES
      allowed_protocols ||= DEFAULT_ALLOWED_PROTOCOLS
      allowed_data_mimes ||= DEFAULT_ALLOWED_DATA_MIMES

      result = normalize_entities(html)
      result = remove_dangerous_tags(result)
      process_tags(result, tags, attributes, allowed_protocols, allowed_data_mimes, on_tag)
    end

    # Remove all HTML tags, returning only text content.
    #
    # @param html [String] the HTML string to strip
    # @return [String] plain text with no HTML tags
    def self.strip(html)
      return '' if html.nil? || html.empty?

      text = normalize_entities(html)
      text = remove_dangerous_tags(text)
      text = text.gsub(/<[^>]*>/, '')
      decode_entities(text)
    end

    # Convert HTML to plain text by removing all tags and decoding entities.
    #
    # Removes dangerous tags (script, style, iframe) along with their content,
    # strips all remaining tags while preserving inner text, and decodes HTML
    # entities so the result is a plain string. Returns an empty string for
    # nil or empty input.
    #
    # @param html [String, nil] the HTML string to convert
    # @return [String] plain text with no HTML tags or entities
    def self.strip_tags(html)
      strip(html)
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

    # Validate a single URL against an allowlist of protocols and optional
    # data: MIME types. Returns the trimmed URL when it's safe to use, or
    # `nil` when the protocol is not permitted.
    #
    # Fragment-only (`#foo`), query-only (`?q=1`), and path-relative (`/foo`)
    # URLs are always considered safe. Protocol-relative URLs (`//example.com`)
    # are treated as paths and also considered safe. Explicit protocols are
    # lowercased before the allowlist check; `data:` URIs are permitted only
    # when the MIME type appears in `allowed_data_mimes`.
    #
    # @param url [String] the URL to inspect
    # @param allowed_protocols [Array<String>] permitted protocol names
    # @param allowed_data_mimes [Array<String>] permitted data: MIME types
    # @return [String, nil] the stripped URL when safe, otherwise nil
    def self.sanitize_url(url, allowed_protocols: DEFAULT_ALLOWED_PROTOCOLS, allowed_data_mimes: DEFAULT_ALLOWED_DATA_MIMES)
      stripped = url.to_s.strip
      return nil if stripped.empty?
      return nil unless valid_url?(stripped, allowed_protocols, allowed_data_mimes)

      stripped
    end

    # @api private
    def self.normalize_entities(html)
      result = html.dup
      # Decode hex entities: &#x3C; &#X3c; etc.
      result = result.gsub(/&#[xX]([0-9a-fA-F]+);/) do
        [Regexp.last_match(1).to_i(16)].pack('U')
      end
      # Decode decimal entities: &#60; etc.
      result.gsub(/&#(\d+);/) do
        [Regexp.last_match(1).to_i].pack('U')
      end
      # Re-encode critical characters so the rest of the pipeline works correctly
      # We only re-encode < > & " ' that came from decoded entities
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
    def self.process_tags(html, allowed_tags, allowed_attributes, allowed_protocols, allowed_data_mimes, on_tag)
      html.gsub(%r{<(/?)(\w+)([^>]*)(/?)>}) do |_match|
        closing = Regexp.last_match(1)
        tag = Regexp.last_match(2).downcase
        attrs = Regexp.last_match(3)
        self_closing = Regexp.last_match(4)

        next '' unless allowed_tags.include?(tag)

        if on_tag && closing != '/'
          attr_hash = parse_attributes(attrs)
          callback_result = on_tag.call(tag, attr_hash)
          # If callback returns nil, skip the tag entirely
          next '' if callback_result.nil?

          # If callback returns a Hash, use it as the new attributes
          if callback_result.is_a?(Hash)
            attr_hash = callback_result
          end
        end

        clean_attrs = if on_tag && closing != '/'
                        filter_attributes_from_hash(tag, attr_hash, allowed_attributes, allowed_protocols, allowed_data_mimes)
                      else
                        filter_attributes(tag, attrs, allowed_attributes, allowed_protocols, allowed_data_mimes)
                      end

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
    def self.parse_attributes(attr_string)
      attrs = {}
      attr_string.scan(/(\w[\w-]*)=(?:"([^"]*)"|'([^']*)'|(\S+))/) do |name, v1, v2, v3|
        attrs[name.downcase] = v1 || v2 || v3
      end
      attrs
    end

    # @api private
    def self.filter_attributes(tag, attr_string, allowed_attributes, allowed_protocols, allowed_data_mimes)
      allowed = allowed_attributes.fetch(tag, [])
      return '' if allowed.empty?

      attrs = []
      attr_string.scan(/(\w[\w-]*)=(?:"([^"]*)"|'([^']*)'|(\S+))/) do |name, v1, v2, v3|
        attr_name = name.downcase
        next if EVENT_ATTRIBUTE_PATTERN.match?(attr_name)
        next unless allowed.include?(attr_name)

        value = v1 || v2 || v3

        if url_attribute?(attr_name) && !valid_url?(value, allowed_protocols, allowed_data_mimes)
          next
        end

        if attr_name == 'style'
          value = sanitize_css(value)
          next if value.empty?
        end

        attrs << "#{attr_name}=\"#{escape_attr(value)}\""
      end

      attrs.join(' ')
    end

    # @api private
    def self.filter_attributes_from_hash(tag, attr_hash, allowed_attributes, allowed_protocols, allowed_data_mimes)
      allowed = allowed_attributes.fetch(tag, [])
      return '' if allowed.empty?

      attrs = []
      attr_hash.each do |attr_name, value|
        attr_name = attr_name.downcase
        next if EVENT_ATTRIBUTE_PATTERN.match?(attr_name)
        next unless allowed.include?(attr_name)

        if url_attribute?(attr_name) && !valid_url?(value, allowed_protocols, allowed_data_mimes)
          next
        end

        if attr_name == 'style'
          value = sanitize_css(value)
          next if value.empty?
        end

        attrs << "#{attr_name}=\"#{escape_attr(value)}\""
      end

      attrs.join(' ')
    end

    # @api private
    def self.url_attribute?(attr_name)
      %w[href src action].include?(attr_name)
    end

    # @api private
    def self.valid_url?(url, allowed_protocols, allowed_data_mimes)
      stripped = url.to_s.strip

      # Allow fragment-only and relative URLs
      return true if stripped.start_with?('#', '/', '?')
      return true unless stripped.include?(':')

      # Check for data: URIs
      if stripped.match?(/\Adata:/i)
        return false if allowed_data_mimes.empty?

        mime_match = stripped.match(/\Adata:([^;,]+)/i)
        return false unless mime_match

        mime = mime_match[1].strip.downcase
        return allowed_data_mimes.include?(mime)
      end

      # Check protocol
      protocol_match = stripped.match(/\A([a-zA-Z][a-zA-Z0-9+\-.]*):/)
      return true unless protocol_match

      protocol = protocol_match[1].downcase
      allowed_protocols.include?(protocol)
    end

    # @api private
    def self.sanitize_css(style_value)
      return '' if DANGEROUS_CSS_PATTERN.match?(style_value)

      safe_declarations = []
      style_value.split(';').each do |declaration|
        declaration = declaration.strip
        next if declaration.empty?

        prop, val = declaration.split(':', 2)
        next unless prop && val

        prop = prop.strip.downcase
        val = val.strip

        next unless SAFE_CSS_PROPERTIES.include?(prop)
        next if DANGEROUS_CSS_PATTERN.match?(val)

        safe_declarations << "#{prop}: #{val}"
      end

      safe_declarations.join('; ')
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

    private_class_method :remove_dangerous_tags, :process_tags, :filter_attributes,
                         :filter_attributes_from_hash, :parse_attributes,
                         :escape_attr, :decode_entities, :normalize_entities,
                         :url_attribute?, :valid_url?, :sanitize_css
  end
end
