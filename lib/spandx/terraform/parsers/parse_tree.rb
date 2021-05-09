# frozen_string_literal: true

module Spandx
  module Terraform
    module Parsers
      class ParseTree < Parslet::Parser
        rule(:anything) { match('.').repeat }
        rule(:alpha) { match['a-zA-Z'] }
        rule(:assign) { str('=') }
        rule(:crlf) { match('[\r\n]') }
        rule(:digit) { match('\d') }
        rule(:dot) { str('.') }
        rule(:eol) { whitespace? >> crlf.repeat }
        rule(:lcurly) { str('{') }
        rule(:number) { digit.repeat }
        rule(:quote) { str('"') }
        rule(:rcurly) { str('}') }
        rule(:space) { match('\s') }
        rule(:pre_release) { hyphen >> (alpha | digit).repeat }
        rule(:pre_release?) { pre_release.maybe }
        rule(:version) { number >> dot >> number >> dot >> number >> pre_release? }
        rule(:whitespace) { space.repeat }
        rule(:whitespace?) { whitespace.maybe }
        rule(:hyphen) { str('-') }

        rule :attribute_name do
          alpha.repeat
        end

        rule :assignment do
          whitespace? >> attribute_name >> whitespace >> assign >> whitespace >> assign >> whitespace >> match('[0-9A-Za-z.~> ]') >> quote >> eol
        end

        rule :value do
          match('[0-9A-Za-z.~> ]')
        end

        rule :version_assignment do
          whitespace? >> str('version') >> whitespace >> assign >> whitespace >> quote >> version.as(:version) >> quote
        end

        rule :constraints do
          anything
        end

        rule :hashes do
          anything
        end

        rule :assignments do
          # (version_assignment | constraints | hashes).repeat
          version_assignment >> eol
        end

        rule :block do
          whitespace >> lcurly >> eol >> assignments >> rcurly >> eol
        end

        rule :identifier do
          whitespace >> quote >> match('[a-zA-Z./]').repeat.as(:name) >> quote >> whitespace
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
