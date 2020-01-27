# frozen_string_literal: true

module Spandx
  module Content
    class Stripper
      def initialize(catalogue)
        @title_regex = /#{START_REGEX}\(?(?:the )?#{Regexp.union(catalogue.map { |x| title_regex_for(x) })}.*?$/i
      end

      def strip(content)
        content = strip_comments(content)
        content = strip_hrs(content)
        content = strip_title(content)
        content = strip_version(content)
        content = strip_cc0_optional(content)
        content = strip_unlicense_optional(content)
        content = strip_hrs(content)
        content = strip_borders(content)
        content = strip_title(content)
        content = strip_version(content)
        content = strip_url(content)
        content = strip_copyright(content)
        content = strip_title(content)
        content = strip_block_markup(content)
        content = substitute(content, REGEXES[:span_markup])
        content = substitute(content, REGEXES[:link_markup])
        content = substitute(content, REGEXES[:all_rights_reserved])
        content = substitute(content, REGEXES[:developed_by])
        content = strip_end_of_terms(content)
        content = substitute(content, REGEXES[:whitespace])
        content = substitute(content, REGEXES[:mit_optional])
        content = content.downcase.strip
      end

      attr_reader :title_regex

      private

      def strip_comments(content)
        lines = content.split("\n")
        return content if lines.count == 1

        regex = REGEXES[:comment_markup]
        return content unless lines.all? { |x| x =~ regex }

        substitute(content, regex)
      end

      def substitute(content, regex)
        content.gsub(regex, ' ').squeeze(' ').strip
      end

      def title_regex_for(license)
        string = license.id.downcase.sub('*', 'u')
        string.sub!(/\Athe /i, '')
        string.sub!(/,? version /, ' ')
        string.sub!(/v(\d+\.\d+)/, '\1')
        string = Regexp.escape(string)
        string = string.sub(/\\ licen[sc]e/i, '(?:\ licen[sc]e)?')
        string = string.sub(/\\ (\d+\\.\d+)/, ',?\s+(?:version\ |v(?:\. )?)?\1')
        string = string.sub(/\bgnu\\ /, '(?:GNU )?')
        title_regex = Regexp.new(string, 'i')

        string = license.id.downcase.sub('-', '[- ]')
        string.sub!('.', '\.')
        string << '(?:\ licen[sc]e)?'
        Regexp.union([title_regex, Regexp.new(string, 'i')])
      end

      def strip_cc0_optional(content)
        return content unless content.include?('associating cc0')

        content = substitute(content, REGEXES[:cc_legal_code])
        content = substitute(content, REGEXES[:cc0_info])
        content = substitute(content, REGEXES[:cc0_disclaimer])
      end

      def strip_unlicense_optional(content)
        return content unless content.include?('unlicense')

        substitute(content, REGEXES[:unlicense_info])
      end

      def strip_hrs(content)
        substitute(content, REGEXES[:hrs])
      end

      def strip_borders(content)
        gsub(content, REGEXES[:border_markup], '\1')
      end

      def gsub(content, from, to)
        content.gsub(from, to)
      end

      def strip_title(content)
        content = substitute(content, title_regex) while content =~ title_regex
        content
      end

      def strip_version(content)
        substitute(content, REGEXES[:version])
      end

      def strip_url(content)
        substitute(content, REGEXES[:url])
      end

      def strip_copyright(content)
        while content =~ COPYRIGHT_REGEX
          content = substitute(content, COPYRIGHT_REGEX)
        end
        content
      end

      def strip_block_markup(content)
        substitute(content, REGEXES[:block_markup])
      end

      def strip_end_of_terms(content)
        body, _partition, _instructions = content.partition(END_OF_TERMS_REGEX)
        body
      end
    end
  end
end
