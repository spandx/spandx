# frozen_string_literal: true

module Spandx
  module Terraform
    module Parsers
      class Hcl < Parslet::Parser
        rule(:alpha) { match['a-zA-Z'] }
        rule(:assign) { str('=') }
        rule(:crlf) { match('[\r\n]') }
        rule(:digit) { match('\d') }
        rule(:dot) { str('.') }
        rule(:eol) { whitespace? >> crlf.repeat }
        rule(:hyphen) { str('-') }
        rule(:lcurly) { str('{') }
        rule(:number) { digit.repeat }
        rule(:quote) { str('"') }
        rule(:rcurly) { str('}') }
        rule(:space) { match('\s') }
        rule(:whitespace) { space.repeat }
        rule(:whitespace?) { whitespace.maybe }

        rule :attribute_name do
          alpha.repeat
        end

        rule :assignment do
          whitespace? >> attribute_name >> whitespace >> assign >> whitespace >> assign >> whitespace >> match('[0-9A-Za-z.~> ]') >> quote >> eol
        end

        rule :value do
          match('[0-9A-Za-z.~> ]').repeat
        end

        rule :argument do
          alpha.repeat.as(:name) >> whitespace >> assign >> whitespace >> quote >> value.as(:value) >> quote
        end

        rule :arguments do
          (argument >> eol).repeat
        end

        rule :block_body do
          arguments.as(:arguments)
        end

        rule :block do
          (alpha.repeat).as(:type) >> identifier >> whitespace >> lcurly >> eol >> block_body >> rcurly >> eol
        end

        rule :identifier do
          whitespace >> quote >> ((alpha | match('[./]')).repeat).as(:name) >> quote >> whitespace
        end

        rule :blocks do
          block.repeat.as(:blocks)
        end

        root(:blocks)
      end
    end
  end
end
