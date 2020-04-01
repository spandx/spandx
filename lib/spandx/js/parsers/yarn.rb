# frozen_string_literal: true
require 'byebug'

module Spandx
  module Js
    module Parsers
      class Token
        attr_accessor :type, :line, :col, :type, :value

        def initialize(line, col, type, value)
          @line = line
          @col = col
          @type = type
          @value = value
        end
      end

      class Yarn < ::Spandx::Core::Parser
        attr_accessor :tokens, :token

        # lockfile version, bump whenever we make backwards incompatible changes
        LOCKFILE_VERSION = 1
        VERSION_REGEX = /^yarn lockfile v(\d+)$/.freeze
        TOKEN_TYPES = {
          boolean: 'BOOLEAN',
          string: 'STRING',
          identifier: 'IDENTIFIER',
          eof: 'EOF',
          colon: 'COLON',
          newline: 'NEWLINE',
          comment: 'COMMENT',
          indent: 'INDENT',
          invalid: 'INVALID',
          number: 'NUMBER',
          comma: 'COMMA',
        }.freeze

        def self.matches?(filename)
          File.basename(filename) == 'yarn.lock'
        end

        def tokenise(input)
          @tokens = []
          last_new_line = false
          line = 1
          col = 1

          build_token = proc { |type, value| Token.new(line, col, type, value) }
          until input.empty?
            chop = 0
            if input[0] == "\n" || input[0] == "\r"
              chop += 1
              chop += 1 if input[1] == "\n"

              line = line + 1
              col = 0
              tokens << build_token.call(TOKEN_TYPES[:newline])

            elsif input[0] == '#'
              chop += 1
              next_new_line = input.index("\n", chop)
              next_new_line = input.length if next_new_line == -1
              val = input[chop..next_new_line]
              chop = next_new_line
              tokens << build_token.call(TOKEN_TYPES[:comment], val)
            elsif input[0] == ' '
              if last_new_line
                indent_size = 1
                i = 1
                while input[i] == ' '
                  indent_size += 1
                  i += 1
                end
                raise StandardError, 'Invalid number of spaces' if indent_size.odd?

                tokens << build_token.call(TOKEN_TYPES[:indent], indent_size / 2)
              else
                chop += 1
              end
            elsif input[0] == '"'
              i = 1
              while i < input.size
                if input[i] == '"'
                  is_escaped = input[i - 1] == '\"' && input[i - 2] != '\"'
                  unless is_escaped
                    i += 1
                    break
                  end
                end
                i += 1
              end

              val = input[0..i]
              chop = i
              byebug
              tokens << build_token.call(TOKEN_TYPES[:string], val.gsub(/\"|:/, ''))
              # tokens << build_token.call(TOKEN_TYPES[:string], val)
            elsif /^[0-9]/.match?(input)
              val = /^[0-9]+/.match(input).to_s
              chop = val.length
              tokens << build_token.call(TOKEN_TYPES[:number], val.to_i)
            elsif /^true/.match?(input)
              tokens << build_token.call(TOKEN_TYPES[:boolean], true)
              chop = 4
            elsif /^false/.match?(input)
              tokens << build_token.call(TOKEN_TYPES[:boolean], false)
              chop = 5
            elsif input[0] == ':'
              chop += 1
              tokens << build_token.call(TOKEN_TYPES[:colon])
            elsif input[0] == ','
              chop += 1
              tokens << build_token.call(TOKEN_TYPES[:comma])
            elsif input.scan(%r{^[a-zA-Z/.-]}).empty? == false
              i = 0
              loop do
                break if [':', "\n", "\r", ',', ' '].include?(input[i])

                i += 1
              end
              name = input[0..i]
              chop = i
              tokens << build_token.call(TOKEN_TYPES[:string], name)
            else
              tokens << build_token.call(TOKEN_TYPES[:invalid])
              next
            end

            if chop.nil?
              tokens << build_token.call(TOKEN_TYPES[:invalid])
              next
            end
            col += chop
            last_new_line = input[0] == "\n" || (input[0] == "\r" && input[1] == "\n")
            input = input[chop..-1]
          end
          tokens << build_token.call(TOKEN_TYPES[:eof])
        end

        def next_token()
          a = tokens.next
          self.token = a
          a
        end

        def parse_yarn(indent = 0)
          obj = {}
          loop do
            prop_token = token
            puts "#{prop_token.inspect}"
            if prop_token.type == TOKEN_TYPES[:newline]
              next_token = next_token()
              next if indent.zero? # if we have 0 indentation then the next token doesn't matter

              break if next_token.type != TOKEN_TYPES[:indent] # if we have no indentation after a newline then we've gone down a level

              if next_token.value == indent
                next_token()
              else
                break
              end
            elsif prop_token.type == TOKEN_TYPES[:indent]
              if prop_token.value == indent
                next_token()
              else
                break
              end
            elsif prop_token.type == TOKEN_TYPES[:eof]
              break
            elsif prop_token.type == TOKEN_TYPES[:string]
              key = prop_token.value

              raise StandartError.new('Expected a key') if key.nil?
              keys = [key]
              next_token()

              #  support multiple keys
              while token.type == TOKEN_TYPES[:comma]
                # byebug

                next_token() # skip comma
                key_token = token

                raise StandardError.new('Expected string') if key_token.type != TOKEN_TYPES[:string]

                keys << key_token.value
                next_token()
              end

              was_colon = token.type == TOKEN_TYPES[:colon]

              next_token() if was_colon

              if is_valid_prop_value_token(token)
                keys.each do |k|
                  obj[k] = token.value
                end

                next_token()
              elsif was_colon
                # parse object
                val = parse_yarn(indent + 1)

                keys.each do |k|
                  obj[k] = val
                end

                break if indent.positive? && token.type != TOKEN_TYPES[:indent]

              else
                raise StandardError, 'Invalid value type'
              end
            elsif prop_token.type == TOKEN_TYPES[:comment]
              next_token()
              next
            else
              raise StandardError, "Unkown token #{token}"
            end
          end

          obj
        end

        def parse(file_path)
          yarn_file = File.read(file_path)
          tokenise(yarn_file)
          self.tokens = tokens.to_enum
          self.token = tokens.peek
          res=parse_yarn()
          convert_objects(res)
        end

        private

        def convert_objects(dependencies)
          deps = Set.new
          dependencies.each do |dependency, details|
            name, _ = dependency.match(/(^.*)(@)(.*)/i).captures
            version = details['version']
            deps.add(::Spandx::Core::Dependency.new(name: name, version: version))
          end
          deps
        end

        # boolean
        def is_valid_prop_value_token(token)
          [TOKEN_TYPES[:boolean], TOKEN_TYPES[:string], TOKEN_TYPES[:number]].include?(token.type)
        end
      end
    end
  end
end
