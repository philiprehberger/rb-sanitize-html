# frozen_string_literal: true

require_relative 'lib/philiprehberger/sanitize_html/version'

Gem::Specification.new do |spec|
  spec.name          = 'philiprehberger-sanitize_html'
  spec.version       = Philiprehberger::SanitizeHtml::VERSION
  spec.authors       = ['Philip Rehberger']
  spec.email         = ['me@philiprehberger.com']

  spec.summary       = 'HTML sanitizer with configurable allow lists for safe user content rendering'
  spec.description   = 'HTML sanitizer with configurable allow lists for tags and attributes. ' \
                       'Strip dangerous elements like script, style, and iframe tags, remove event ' \
                       'attributes, and safely render user-generated content.'
  spec.homepage      = 'https://github.com/philiprehberger/rb-sanitize-html'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = spec.homepage
  spec.metadata['changelog_uri']         = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['bug_tracker_uri']       = "#{spec.homepage}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
