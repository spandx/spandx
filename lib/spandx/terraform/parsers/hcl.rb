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
        rule(:major) { number }
        rule(:major_minor) { (number >> dot >> number) }
        rule(:major_minor_patch) { number >> dot >> number >> dot >> number }
        rule(:number) { digit.repeat }
        rule(:pre_release) { hyphen >> (alpha | digit).repeat }
        rule(:pre_release?) { pre_release.maybe }
        rule(:quote) { str('"') }
        rule(:rcurly) { str('}') }
        rule(:space) { match('\s') }
        rule(:tilda_wacka) { str('~>') }
        rule(:version) { number >> dot >> number >> dot >> number >> pre_release? }
        rule(:comment) { (str('#') | str('//')) >> ((str("\n") >> str("\r").maybe).absent? >> any).repeat >> eol }
        rule(:multiline_comment) { str('/*') >> (str('*/').absent? >> any).repeat >> str('*/') }
        rule(:whitespace) { (multiline_comment | comment | space).repeat }
        rule(:whitespace?) { whitespace.maybe }
        rule(:greater_than_or_equal_to) { str('>=') }

        rule :attribute_name do
          alpha.repeat
        end

        rule :assignment do
          whitespace? >> attribute_name >> whitespace >> assign >> whitespace >> assign >> whitespace >> match('[0-9A-Za-z.~> ]') >> quote >> eol
        end

        rule :value do
          match('[0-9A-Za-z.~> ]').repeat
        end

        rule(:version_constraint) do
          pessimistic_version_constraint | greater_than_or_equal_to_version
        end

        rule :version_assignment do
          str('version') >> whitespace >> assign >> whitespace >> quote >> version.as(:version) >> quote
        end

        rule :constraint_assignment do
          str('constraints') >> whitespace >> assign >> whitespace >> quote >> version_constraint.as(:constraints) >> quote
        end

        rule(:pessimistic_version_constraint) do
          tilda_wacka >> whitespace >> (
            major_minor_patch |
            major_minor |
            major
          )
        end

        rule(:greater_than_or_equal_to_version) do
          greater_than_or_equal_to >> whitespace >> (
            major_minor_patch |
            major_minor |
            major
          )
        end

        rule :argument do
          alpha.repeat.as(:name) >> whitespace >> assign >> whitespace >> quote >> value.as(:value) >> quote
        end

        rule :arguments do
          (argument >> eol).repeat
        end

        rule :identifier do
          whitespace >> quote >> ((alpha | match('[./]')).repeat).as(:name) >> quote >> whitespace
        end

        rule :block_body do
          arguments.as(:arguments)
        end

        rule :block do
          whitespace? >> (alpha.repeat).as(:type) >> identifier >> whitespace >> lcurly >> eol >> block_body >> rcurly >> eol
        end

        rule :blocks do
          block.repeat.as(:blocks)
        end

        root(:blocks)
      end
    end
  end
end
