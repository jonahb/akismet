require 'lib/akismet/version'

Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
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
end