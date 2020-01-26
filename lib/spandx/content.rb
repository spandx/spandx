# frozen_string_literal: true

module Spandx
  # https://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Dice%27s_coefficient#Ruby
  class Content
    START_REGEX = /\A\s*/.freeze
    END_OF_TERMS_REGEX = /^[\s#*_]*end of terms and conditions\s*$/i.freeze
    REGEXES = {
      hrs: /^\s*[=\-\*]{3,}\s*$/,
      all_rights_reserved: /#{START_REGEX}all rights reserved\.?$/i,
      whitespace: /\s+/,
      markdown_headings: /#{START_REGEX}#+/,
      version: /#{START_REGEX}version.*$/i,
      span_markup: /[_*~]+(.*?)[_*~]+/,
      link_markup: /\[(.+?)\]\(.+?\)/,
      block_markup: /^\s*>/,
      border_markup: /^[\*-](.*?)[\*-]$/,
      comment_markup: %r{^\s*?[/\*]{1,2}},
      url: %r{#{START_REGEX}https?://[^ ]+\n},
      bullet: /\n\n\s*(?:[*-]|\(?[\da-z]{1,2}[)\.])\s+/i,
      developed_by: /#{START_REGEX}developed by:.*?\n\n/im,
      quote_begin: /[`'"‘“]/,
      quote_end: /[`'"’”]/,
      cc_legal_code: /^\s*Creative Commons Legal Code\s*$/i,
      cc0_info: /For more information, please see\s*\S+zero\S+/im,
      cc0_disclaimer: /CREATIVE COMMONS CORPORATION.*?\n\n/im,
      unlicense_info: /For more information, please.*\S+unlicense\S+/im,
      mit_optional: /\(including the next paragraph\)/i
    }.freeze
    COPYRIGHT_SYMBOLS = Regexp.union([/copyright/i, /\(c\)/i, "\u00A9", "\xC2\xA9"])
    COPYRIGHT_REGEX = /#{START_REGEX}(?:portions )?(\s*#{COPYRIGHT_SYMBOLS}.*$)+$/i.freeze
    NORMALIZATIONS = {
      lists: { from: /^\s*(?:\d\.|\*)\s+([^\n])/, to: '- \1' },
      https: { from: /http:/, to: 'https:' },
      ampersands: { from: '&', to: 'and' },
      dashes: { from: /(?<!^)([—–-]+)(?!$)/, to: '-' },
      quotes: {
        from: /#{REGEXES[:quote_begin]}+([\w -]*?\w)#{REGEXES[:quote_end]}+/,
        to: '"\1"'
      }
    }.freeze
    VARIETAL_WORDS = {
      'acknowledgment' => 'acknowledgement',
      'analogue' => 'analog',
      'analyse' => 'analyze',
      'artefact' => 'artifact',
      'authorisation' => 'authorization',
      'authorised' => 'authorized',
      'calibre' => 'caliber',
      'cancelled' => 'canceled',
      'capitalisations' => 'capitalizations',
      'catalogue' => 'catalog',
      'categorise' => 'categorize',
      'centre' => 'center',
      'emphasised' => 'emphasized',
      'favour' => 'favor',
      'favourite' => 'favorite',
      'fulfil' => 'fulfill',
      'fulfilment' => 'fulfillment',
      'initialise' => 'initialize',
      'judgment' => 'judgement',
      'labelling' => 'labeling',
      'labour' => 'labor',
      'licence' => 'license',
      'maximise' => 'maximize',
      'modelled' => 'modeled',
      'modelling' => 'modeling',
      'offence' => 'offense',
      'optimise' => 'optimize',
      'organisation' => 'organization',
      'organise' => 'organize',
      'practise' => 'practice',
      'programme' => 'program',
      'realise' => 'realize',
      'recognise' => 'recognize',
      'signalling' => 'signaling',
      'sub-license' => 'sublicense',
      'sub license' => 'sublicense',
      'utilisation' => 'utilization',
      'whilst' => 'while',
      'wilful' => 'wilfull',
      'non-commercial' => 'noncommercial',
      'cent' => 'percent',
      'owner' => 'holder'
    }.freeze
    STRIP_METHODS = %i[
      cc0_optional
      unlicense_optional
      hrs
      markdown_headings
      borders
      title
      version
      url
      copyright
      title
      block_markup
      span_markup
      link_markup
      all_rights_reserved
      developed_by
      end_of_terms
      whitespace
      mit_optional
    ].freeze

    attr_reader :tokens, :catalogue, :content

    def initialize(content, catalogue)
      @content = content
      @catalogue = catalogue
      @tokens = tokenize(content)
    end

    def similar?(other)
      overlap = (wordset & other.wordset).size
      total = wordset.size + other.wordset.size
      100.0 * (overlap * 2.0 / total)
    end

    def similar?(other)
      overlap = (tokens & other.tokens).size
      total = tokens.size + other.tokens.size
      100.0 * (overlap * 2.0 / total)
    end

    def wordset
      @wordset ||= content_normalized&.scan(/(?:\w(?:'s|(?<=s)')?)+/)&.to_set
    end

    private

    def tokenize(string)
      #string.downcase.split(/\W+/)
      string.downcase.scan(/(?:\w(?:'s|(?<=s)')?)+/).to_set
    end

    def content_normalized(wrap: nil)
      @content_normalized ||=
        begin
          @_content = content_without_title_and_version.downcase
          (NORMALIZATIONS.keys + %i[spelling bullets]).each { |x| normalize(x) }
          STRIP_METHODS.each { |x| strip(x) }

          _content
        end

      if wrap.nil?
        @content_normalized
      else
        Licensee::ContentHelper.wrap(@content_normalized, wrap)
      end
    end

    def content_without_title_and_version
      @content_without_title_and_version ||=
        begin
          @_content = nil
          [
            :comments,
            :hrs,
            #:html,
            #:markdown_headings,
            :title,
            :version
          ].each { |x| strip(x) }
          _content
        end
    end

    def _content
      @_content ||= content.to_s.dup.strip
    end

    def strip(regex_or_sym)
      return unless _content

      if regex_or_sym.is_a?(Symbol)
        meth = "strip_#{regex_or_sym}"
        return send(meth) if respond_to?(meth, true)

        unless REGEXES[regex_or_sym]
          raise ArgumentError, "#{regex_or_sym} is an invalid regex reference"
        end

        regex_or_sym = REGEXES[regex_or_sym]
      end

      @_content = _content.gsub(regex_or_sym, ' ').squeeze(' ').strip
    end

    def strip_comments
      lines = _content.split("\n")
      return if lines.count == 1
      return unless lines.all? { |line| line =~ REGEXES[:comment_markup] }

      strip(:comment_markup)
    end

    def strip_cc0_optional
      return unless _content.include? 'associating cc0'

      strip(REGEXES[:cc_legal_code])
      strip(REGEXES[:cc0_info])
      strip(REGEXES[:cc0_disclaimer])
    end

    def strip_unlicense_optional
      return unless _content.include? 'unlicense'

      strip(REGEXES[:unlicense_info])
    end

    def strip_borders
      normalize(REGEXES[:border_markup], '\1')
    end

    def strip_copyright
      strip(COPYRIGHT_REGEX) while _content =~ COPYRIGHT_REGEX
    end

    def strip_end_of_terms
      body, _partition, _instructions = _content.partition(END_OF_TERMS_REGEX)
      @_content = body
    end

    def strip_title
      strip(title_regex) while _content =~ title_regex
    end

    def title_regex
      @title_regex ||= begin
        titles = catalogue.map { |x| title_regex_for(x) }
        /#{START_REGEX}\(?(?:the )?#{Regexp.union titles}.*?$/i
      end
    end

    def normalize(from_or_key, to = nil)
      operation = { from: from_or_key, to: to } if to
      operation ||= NORMALIZATIONS[from_or_key]

      if operation
        @_content = _content.gsub operation[:from], operation[:to]
      elsif respond_to?("normalize_#{from_or_key}", true)
        send("normalize_#{from_or_key}")
      else
        raise ArgumentError, "#{from_or_key} is an invalid normalization"
      end
    end

    def normalize_spelling
      normalize(/\b#{Regexp.union(VARIETAL_WORDS.keys)}\b/, VARIETAL_WORDS)
    end

    def normalize_bullets
      normalize(REGEXES[:bullet], "\n\n* ")
      normalize(/\)\s+\(/, ')(')
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
      title_regex = Regexp.new string, 'i'

      string = license.id.downcase.sub('-', '[- ]')
      string.sub!('.', '\.')
      string << '(?:\ licen[sc]e)?'
      key_regex = Regexp.new string, 'i'

      parts = [title_regex, key_regex]
      # if meta.nickname
      # parts.push Regexp.new meta.nickname.sub(/\bGNU /i, '(?:GNU )?')
      # end

      Regexp.union(parts)
    end
  end
end
