# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in solargraph-herb.gemspec
gemspec

# Development Dependencies
gem 'bundler'             # Dependency management
gem 'debug'               # Debugging
gem 'rake'                # Build
gem 'rspec'               # Testing
gem 'rubocop'             # Linting
gem 'rubocop-yard'        # YARD documentation linting
gem 'simplecov'           # Code coverage
gem 'simplecov-cobertura' # Code coverage

# Solargraph with the unreleased hooks this plugin needs: transform_source (castwide/solargraph#1489) and binding a
# transformed source to a closure. A local checkout of the `herb-variable-definitions` branch (stacked on `cucumber`) when
# there is one (or SOLARGRAPH_PATH), else that branch on GitHub
solargraph_path = ENV.fetch('SOLARGRAPH_PATH') do
  File.expand_path('~/Projects/open_source/solargraph__worktrees/herb-variable-definitions')
end
if Dir.exist?(solargraph_path)
  gem 'solargraph', path: solargraph_path
else
  gem 'solargraph', github: 'lekemula/solargraph', branch: 'herb-variable-definitions'
end
