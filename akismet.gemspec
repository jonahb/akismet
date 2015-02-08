require File.expand_path('../lib/akismet/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'akismet'
  s.version = Akismet::VERSION
  s.summary = 'A Ruby client for the Akismet API'
  s.description = s.summary
  s.license = 'MIT'
  s.author = 'Jonah Burke'
  s.email = 'jonah@jonahb.com'
  s.homepage = 'http://github.com/jonahb/akismet'
  s.has_rdoc = 'yard'
  s.files = Dir[ 'README.md', 'MIT-LICENSE', 'lib/**/*' ]
  s.require_path = 'lib'

  s.add_development_dependency 'bundler', '~> 1.7'
  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'yard', '~> 0.8.7'
end
