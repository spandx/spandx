# frozen_string_literal: true

module Spandx
  module Cli
    module Commands
      class Pull
        def initialize(options)
          @options = options
        end

        def execute(output: $stdout)
          Spandx.git.each_value do |db|
            with_spinner("Updating #{db.url}...", output: output) do
              db.update!
            end
          end

          with_spinner('Rebuilding index...', output: output) do
            Spandx::Core::Dependency::PACKAGE_MANAGERS.values.uniq.each do |type|
              Spandx::Core::Cache
                .new(type, root: Spandx.git[:cache].root.join('.index'))
                .rebuild_index
            end
          end
          output.puts 'OK'
        end

        private

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
