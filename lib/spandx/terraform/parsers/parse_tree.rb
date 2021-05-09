# frozen_string_literal: true

module Spandx
  module Terraform
    module Parsers
      class ParseTree < Parslet::Parser
        rule :crlf do
          match('[\r\n]')
        end

        rule :eol do
          whitespace? >> crlf.repeat(1)
        end

        rule :whitespace? do
          whitespace.maybe
        end

        rule :whitespace do
          match('[ ]').repeat
        end

        rule :anything do
          match('.').repeat
        end

        rule :attribute_name do
          match('[a-z]').repeat
        end

        rule :assignment do
          whitespace? >> attribute_name >> whitespace >> str('=') >> whitespace >> str("=") >> whitespace >> match('[0-9A-Za-z.~> ]') >> str('"') >> eol
        end

        rule :assignments do
          assignment.repeat
        end

        rule :block do
          whitespace >> str("{") >> eol >> assignments >> str("}") >> eol
        end

        rule :identifier do
          whitespace >> str('"') >> match('[a-zA-Z./]').repeat.as(:name) >> str('"') >> whitespace
        end

        rule :provider do
          (str("provider") >> identifier >> block).as(:provider)
        end

        rule :providers do
          provider.repeat
        end

        root(:providers)
      end
    end
  end
end
