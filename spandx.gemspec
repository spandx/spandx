# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'spandx/version'

Gem::Specification.new do |spec|
  spec.name          = 'spandx'
  spec.version       = Spandx::VERSION
  spec.authors       = ['Can Eldem', 'mo khan']
  spec.email         = ['eldemcan@gmail.com', 'mo@mokhan.ca']

  spec.summary       = 'A ruby interface to the SPDX catalogue.'
  spec.description   = 'Spanx is a ruby API for interacting with the spdx.org software license catalogue. This gem includes a command line interface to scan a software project for the software licenses that are associated with each dependency in the project. Spandx also allows you to hook additional information for each dependency found. For instance, you can add plugin to Spandx to find and report vulnerabilities for the dependencies it found.'
  spec.homepage      = 'https://spandx.github.io/'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.5.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/spandx/spandx'
  spec.metadata['changelog_uri'] = 'https://github.com/spandx/spandx/blob/main/CHANGELOG.md'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('exe/*') +
      Dir.glob('ext/**/**/*.{rb,c,h}') +
      Dir.glob('lib/**/**/*.{rb}') +
      Dir.glob('*.{md,gemspec,txt}')
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.extensions    = ['ext/spandx/extconf.rb']

  spec.add_dependency 'addressable', '~> 2.7'
  spec.add_dependency 'bundler', '>= 1.16', '< 3.0.0'
  spec.add_dependency 'net-hippie', '~> 1.0'
  spec.add_dependency 'nokogiri', '~> 1.10'
  spec.add_dependency 'oj', '~> 3.10'
  spec.add_dependency 'parslet', '~> 2.0'
  spec.add_dependency 'terminal-table', '~> 1.8'
  spec.add_dependency 'thor'
  spec.add_dependency 'tty-spinner', '~> 0.9'
  spec.add_dependency 'zeitwerk', '~> 2.3'

  spec.add_development_dependency 'benchmark-ips', '~> 2.8'
  spec.add_development_dependency 'bundler-audit', '~> 0.6'
  spec.add_development_dependency 'byebug', '~> 11.1'
  spec.add_development_dependency 'licensed', '~> 2.8'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rake-compiler', '~> 1.1'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-benchmark', '~> 0.5'
  spec.add_development_dependency 'rubocop', '~> 0.52'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.22'
  spec.add_development_dependency 'ruby-prof', '~> 1.3'
  spec.add_development_dependency 'vcr', '~> 6.0'
  spec.add_development_dependency 'webmock', '~> 3.7'
end
