# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'spandx/version'

Gem::Specification.new do |spec|
  spec.name          = 'spandx'
  spec.version       = Spandx::VERSION
  spec.authors       = ['mo khan']
  spec.email         = ['mo@mokhan.ca']

  spec.summary       = 'A ruby interface to the SPDX catalogue.'
  spec.description   = 'A ruby interface to the SPDX catalogue. With a CLI that can scan project lockfiles to list out software licenses for each dependency'
  spec.homepage      = 'https://github.com/mokhan/spandx'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.4.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/mokhan/spandx'
  spec.metadata['changelog_uri'] = 'https://github.com/mokhan/spandx/blob/master/CHANGELOG.md'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('exe/*') +
      Dir.glob('lib/**/**/*.{rb}') +
      Dir.glob('*.{md,gemspec,txt}')
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'addressable', '~> 2.7'
  spec.add_dependency 'bundler', '>= 1.16', '< 3.0.0'
  spec.add_dependency 'net-hippie', '~> 0.3'
  spec.add_dependency 'nokogiri', '~> 1.10'
  spec.add_dependency 'thor'

  spec.add_development_dependency 'bundler-audit', '~> 0.6'
  spec.add_development_dependency 'byebug', '~> 11.1'
  spec.add_development_dependency 'jaro_winkler', '~> 1.5'
  spec.add_development_dependency 'licensed', '~> 2.8'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-benchmark', '~> 0.5'
  spec.add_development_dependency 'rubocop', '~> 0.52'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.22'
  spec.add_development_dependency 'text', '~> 1.3'
  spec.add_development_dependency 'vcr', '~> 5.0'
  spec.add_development_dependency 'webmock', '~> 3.7'
end
