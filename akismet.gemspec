# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'akismet/version'

Gem::Specification.new do |spec|
  spec.name = 'akismet'
  spec.version = Akismet::VERSION
  spec.author = ['Jonah Burke']
  spec.email = ['jonah@jonahb.com']
  spec.summary = 'A Ruby client for the Akismet API'
  spec.homepage = 'http://github.com/jonahb/akismet'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.4'
  spec.require_paths = ['lib']
  spec.files = Dir['README.md', 'LICENSE.txt', '.yardopts', 'lib/**/*']

  spec.add_development_dependency 'bundler', '>= 1.7'
  spec.add_development_dependency 'minitest', '~> 5.11'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'yard', '~> 0.9.20'
end
