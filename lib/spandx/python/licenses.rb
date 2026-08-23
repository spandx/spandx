# frozen_string_literal: true

module Spandx
  module Python
    # PyPI's `info.license` is free text. It is often an SPDX id, sometimes a
    # url, and frequently the entire license body -- values over 34KB were
    # measured. Only an identifier belongs in an index: a body is megabytes of
    # bloat, and its newlines break the line-oriented shard format that the
    # .idx offsets are built from. So anything longer than an identifier is
    # dropped in favour of the trove classifiers.
    class Licenses
      MAX_LENGTH = 64
      CLASSIFIER_PREFIX = 'License ::'

      def initialize(catalogue)
        @catalogue = catalogue
      end

      # Pure -- no network.
      def for(info)
        from_license(info['license']) || from_classifiers(info['classifiers']) || []
      end

      private

      attr_reader :catalogue

      def from_license(value)
        text = value.to_s.strip
        return if text.empty? || text.length > MAX_LENGTH

        [catalogue[text]&.id || catalogue.find_by_url(text)&.id || text]
      end

      def from_classifiers(classifiers)
        ids = Array(classifiers).filter_map { |x| from_classifier(x) }.uniq
        ids.empty? ? nil : ids
      end

      # "License :: OSI Approved :: MIT License" -> "MIT"
      def from_classifier(classifier)
        return unless classifier.to_s.start_with?(CLASSIFIER_PREFIX)

        name = classifier.to_s.split(' :: ').last.to_s.strip
        return if name.empty? || name == 'OSI Approved'

        catalogue.find_by_name(name)&.id || name
      end
    end
  end
end
