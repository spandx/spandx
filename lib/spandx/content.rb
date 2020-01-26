# frozen_string_literal: true

require 'spandx/content/stripper'
require 'spandx/content/text'

module Spandx
  module Content
    START_REGEX = /\A\s*/.freeze
    END_OF_TERMS_REGEX = /^[\s#*_]*end of terms and conditions\s*$/i.freeze
    COPYRIGHT_SYMBOLS = Regexp.union([/copyright/i, /\(c\)/i, "\u00A9", "\xC2\xA9"])
    COPYRIGHT_REGEX = /#{START_REGEX}(?:portions )?(\s*#{COPYRIGHT_SYMBOLS}.*$)+$/i.freeze
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
    WORDS = {
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
  end
end
