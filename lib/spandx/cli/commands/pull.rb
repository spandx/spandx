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
            output.puts "Updating #{db.url}..."
            db.update!
          end
          Spandx::Core::Dependency::PACKAGE_MANAGERS.values.uniq.each do |type|
            Spandx::Core::Cache
              .new(type, root: Spandx.git[:cache].root.join('.index'))
              .rebuild_index(output: output)
          end
          output.puts 'OK'
        end
      end
    end
  end
end
