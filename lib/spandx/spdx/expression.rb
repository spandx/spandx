# frozen_string_literal: true

module Spandx
  module Spdx
    class Expression < Parslet::Parser
      # https://spdx.org/spdx-specification-21-web-version
      #
      # idstring              = 1*(ALPHA / DIGIT / "-" / "." )
      # license-id            = <short form license identifier in Appendix I.1>
      # license-exception-id  = <short form license exception identifier in Appendix I.2>
      # license-ref           = ["DocumentRef-"1*(idstring)":"]"LicenseRef-"1*(idstring)
      # simple-expression = license-id / license-id"+" / license-ref
      # compound-expression =  1*1(simple-expression /
      #                             simple-expression "WITH" license-exception-id /
      #                             compound-expression "AND" compound-expression /
      #                             compound-expression "OR" compound-expression ) /
      #                           "(" compound-expression ")" )
      #
      # license-expression =  1*1(simple-expression / compound-expression)
      rule(:lparen) { str('(') }
      rule(:rparen) { str(')') }
      rule(:digit) { match('\d') }
      rule(:space) { match('\s') }
      rule(:space?) { space.maybe }
      rule(:alpha) { match['a-zA-Z'] }
      rule(:colon) { str(':') }
      rule(:dot) { str('.') }
      rule(:plus) { str('+') }
      rule(:plus?) { plus.maybe }
      rule(:hyphen) { str('-') }
      rule(:hyphen?) { hyphen.maybe }
      rule(:with_op) { str('with') | str('WITH') }
      rule(:and_op) { str('AND') | str('and') }
      rule(:or_op) { str('OR') | str('or') }

      # idstring              = 1*(ALPHA / DIGIT / "-" / "." )
      rule(:id_character) { alpha | digit | hyphen | dot }
      rule(:id_string) { id_character.repeat(1) }

      # license-id = <short form license identifier in Appendix I.1>
      rule(:license_id) do
        id_string
      end

      # license-ref = ["DocumentRef-"1*(idstring)":"]"LicenseRef-"1*(idstring)
      rule(:license_ref) do
        (str('DocumentRef-') >> id_string >> colon).repeat(0, 1) >> str('LicenseRef-') >> id_string
      end

      # simple-expression = license-id / license-id"+" / license-ref
      rule(:simple_expression) do
        license_id >> plus? | license_ref
      end

      rule(:exception) do
        match['eE'] >> str('xception')
      end

      rule(:version) do
        digit >> dot >> digit
      end

      # license-exception-id = <short form license exception identifier in Appendix I.2>
      rule(:license_exception_id) do
        # alpha.repeat(1) >> hyphen >> exception >> (hyphen? >> version)
        id_string
      end

      # simple-expression "WITH" license-exception-id
      rule(:with_expression) do
        simple_expression.as(:left) >> space >> with_op.as(:op) >> space >> license_exception_id.as(:right)
      end

      rule(:binary_operator) do
        (or_op | and_op).as(:op)
      end

      rule(:binary_right) do
        space >> binary_operator >> space >> (binary_expression | simple_expression).as(:right)
      end

      # compound-expression "AND" compound-expression
      # compound-expression "OR" compound-expression
      rule(:binary_expression) do
        simple_expression.as(:left) >> binary_right
      end

      # (BSD-2-Clause OR MIT OR Apache-2.0)
      #
      #
      # compound-expression =  1*1(
      #     simple-expression /
      #     simple-expression "WITH" license-exception-id /
      #     compound-expression "AND" compound-expression /
      #     compound-expression "OR" compound-expression
      #   ) / "(" compound-expression ")")
      rule(:compound_expression) do
        lparen >> compound_expression >> space? >> rparen |
          (
            binary_expression |
            with_expression |
            simple_expression.as(:left)
          ).repeat(1, 1)
      end

      # license-expression =  1*1(simple-expression / compound-expression)
      rule(:license_expression) do
        (compound_expression | simple_expression).repeat(1, 1)
      end

      root(:license_expression)
    end
  end
end
