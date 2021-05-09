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
        rule(:tilda_wacka) { str("~>") }
        rule(:version) { number >> dot >> number >> dot >> number >> pre_release? }
        rule(:whitespace) { space.repeat }
        rule(:whitespace?) { whitespace.maybe }
        rule(:greater_than_or_equal_to) { str('>=') }

        rule :attribute_name do
          alpha.repeat
        end

        rule :assignment do
          whitespace? >> attribute_name >> whitespace >> assign >> whitespace >> assign >> whitespace >> match('[0-9A-Za-z.~> ]') >> quote >> eol
        end

        rule :value do
          match('[0-9A-Za-z.~> ]')
        end

        rule(:version_constraint) do
          pessimistic_version_constraint | greater_than_or_equal_to_version
        end

        rule :version_assignment do
          str('version') >> whitespace >> assign >> whitespace >> quote >> version.as(:version) >> quote
        end

        rule :constraint_assignment do
          str("constraints") >> whitespace >> assign >> whitespace >> quote >> version_constraint.as(:constraints) >> quote
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
          (
            str('version') |
            str('constraints')
          ).as(:argument) >> whitespace >> assign >> whitespace >> quote >> (
            version |
            version_constraint
          ).as(:value) >> quote
        end

        rule :arguments do
          #((version_assignment | constraint_assignment) >> eol).repeat
          (argument >> eol).repeat
        end

        rule :block do
          whitespace >> lcurly >> eol >> arguments >> rcurly >> eol
        end

        rule :identifier do
          whitespace >> quote >> ((alpha | match('[./]')).repeat).as(:name) >> quote >> whitespace
        end

        rule :provider do
          (str('provider') >> identifier >> block).as(:provider)
        end

        rule :providers do
          provider.repeat
        end

        root(:providers)
      end
    end
  end
end
