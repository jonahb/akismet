# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
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
  spec.required_ruby_version = '>= 1.9.3'
  spec.require_paths = ['lib']
  spec.files = Dir[ 'README.md', 'LICENSE.txt', '.yardopts', 'lib/**/*' ]

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'yard', '~> 0.8.7'
end
