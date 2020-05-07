
module Spandx
  module Spdx
    class Expression < Parslet::Parser
=begin
https://spdx.org/spdx-specification-21-web-version

idstring              = 1*(ALPHA / DIGIT / "-" / "." )
license-id            = <short form license identifier in Appendix I.1>
license-exception-id  = <short form license exception identifier in Appendix I.2>
license-ref           = ["DocumentRef-"1*(idstring)":"]"LicenseRef-"1*(idstring)
simple-expression = license-id / license-id”+” / license-ref
compound-expression =  1*1(simple-expression /
                            simple-expression "WITH" license-exception-id /
                            compound-expression "AND" compound-expression /
                            compound-expression "OR" compound-expression ) /
                          "(" compound-expression ")" )

license-expression =  1*1(simple-expression / compound-expression)
=end
      rule(:lparen) { str('(') }
      rule(:rparen) { str(')') }
      rule(:digit) { match('\d') }
      rule(:quote) { str('"') }
      rule(:single_quote) { str("'") }
      rule(:space) { match('\s') }
      rule(:alpha) { match['a-zA-Z'] }
      rule(:dot) { str('.') }
      rule(:colon) { str(':') }
      rule(:hyphen) { str('-') }
      rule(:underscore) { str('_') }
      rule(:with_op) { str('with') }
      rule(:and_op) { str('AND') | str("and") }
      rule(:or_op) { str('OR') | str('or') }

      #idstring              = 1*(ALPHA / DIGIT / "-" / "." )
      rule(:id_character) { alpha | digit | hyphen | dot }
      rule(:id_string) { id_character.repeat(1, nil) }

      # license-id = <short form license identifier in Appendix I.1>
      rule(:license_id) do
        id_string
      end

      rule(:license_ref) do
      end

      # simple-expression = license-id / license-id”+” / license-ref
      rule(:simple_expression) do
        license_id# | license_ref
      end

      # license-exception-id = <short form license exception identifier in Appendix I.2>
      rule(:license_exception_id) do
        # TODO:: Update to match exceptions list
        str('389-exception')
      end

      # simple-expression "WITH" license-exception-id
      rule(:with_expression) do
        simple_expression >> space >> with_op >> space >> license_exception_id
      end

      # compound-expression "AND" compound-expression
      rule(:and_expression) do
        compound_expression_atom >> space >> and_op >> space >> compound_expression_atom
      end

      # compound-expression "OR" compound-expression
      rule(:or_expression) do
        compound_expression_atom >> space >> or_op >> space >> compound_expression_atom
      end

      rule(:compound_expression_atom) do
        simple_expression | with_expression | and_expression | or_expression
      end

      #compound-expression =  1*1(simple-expression /
      #simple-expression "WITH" license-exception-id /
      #compound-expression "AND" compound-expression /
      #compound-expression "OR" compound-expression ) /
      #"(" compound-expression ")" )
      rule(:compound_expression) do
        compound_expression_atom | lparen >> compound_expression_atom >> rparen

        #(
          #simple_expression |
          #with_expression |
          #and_expression |
          #or_expression |
          #( lparen >> space >> ( simple_expression >> with_expression >> and_expression >> or_expression ) >> space >> rparen )
        #).repeat(1, nil)
        #( lparen >> compound_expression >> rparen )
      end

      # license-expression =  1*1(simple-expression / compound-expression)
      rule(:license_expression) do
        simple_expression | compound_expression
      end

      root(:license_expression)
    end
  end
end
