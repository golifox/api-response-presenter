# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'api_response/version'

Gem::Specification.new do |s|
  s.name        = 'api-response-presenter'
  s.author      = 'David Rybolovlev'
  s.email       = 'i@golifox.ru'
  s.license     = 'MIT'
  s.version     = ApiResponse::VERSION.dup

  s.summary     = 'Gem for presenting API responses from Faraday and RestClient.'
  s.description = s.summary
  s.files       = Dir['README.md', 'LICENSE', 'CHANGELOG.md', 'api_response_presenter.gemspec', 'lib/**/*.rb']
  s.executables = []
  s.require_paths = ['lib']

  s.metadata = {'rubygems_mfa_required' => 'true'}

  s.required_ruby_version = '>= 2.7.4'

  s.add_runtime_dependency 'dry-configurable', '~> 1.0'
  s.add_runtime_dependency 'dry-initializer', '~> 3.0'
  s.add_runtime_dependency 'dry-monads', '~> 1.6'
  s.add_runtime_dependency 'dry-types', '~> 1.5'
  s.add_runtime_dependency 'oj', '~> 3.13'
  s.add_runtime_dependency 'zeitwerk', '~> 2.4'

  s.add_runtime_dependency 'dry-struct', '~> 1.5'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
end
