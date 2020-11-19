# frozen_string_literal: true

module Spandx
  module Cli
    module Commands
      class Pull
        attr_reader :cache_dir, :rubygems_cache_dir

        def initialize(options)
          @options = options
          @cache_dir = Spandx.git[:cache].root.join('.index')
          @rubygems_cache_dir = Spandx.git[:rubygems].root.join('.index')
        end

        def execute(output: $stderr)
          sync(output)
          build(output, ::Spandx::Core::Dependency::PACKAGE_MANAGERS.values.uniq)
          index_files_in(cache_dir, rubygems_cache_dir).each do |item|
            output.puts item.to_s.gsub(Dir.home, '~')
          end
          output.puts 'OK'
        end

        private

        def sync(output)
          Spandx.git.each_value do |db|
            with_spinner("Updating #{db.url}...", output: output) do
              db.update!
            end
          end
        end

        def build(output, sources)
          with_spinner('Building index...', output: output) do
            sources.each do |source|
              Spandx::Core::Cache.new(source, root: cache_dir).rebuild_index
            end
            Spandx::Core::Cache.new(:rubygems, root: rubygems_cache_dir).rebuild_index
          end
        end

        def with_spinner(message, output:)
          spinner = TTY::Spinner.new("[:spinner] #{message}", output: output)
          spinner.auto_spin
          yield
          spinner.success('(done)')
        rescue StandardError => error
          spinner.error("(#{error.message})")
        ensure
          spinner.stop
        end

        def index_files_in(*dirs)
          dirs.map { |x| x.glob('**/*.idx') }.flatten.sort
        end
      end
    end
  end
end
