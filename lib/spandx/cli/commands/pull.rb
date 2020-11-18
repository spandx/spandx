# frozen_string_literal: true

module Spandx
  module Cli
    module Commands
      class Pull
        def initialize(options)
          @options = options
        end

        def execute(output: $stderr)
          sync(output)
          build(output, ::Spandx::Core::Dependency::PACKAGE_MANAGERS.values.uniq)
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
          index_path = Spandx.git[:cache].root.join('.index')

          with_spinner('Rebuilding index...', output: output) do
            sources.each do |source|
              Spandx::Core::Cache
                .new(source, root: index_path)
                .rebuild_index
            end
          end
        end

        def with_spinner(message, output:)
          spinner = TTY::Spinner.new("[:spinner] #{message}", clear: false, output: output)
          spinner.auto_spin
          yield
          spinner.success('(done)')
        ensure
          spinner.stop
        end
      end
    end
  end
end
