# frozen_string_literal: true

module Spandx
  module Core
    class Dependency
      PACKAGE_MANAGERS = {
        Spandx::Dotnet::Parsers::Csproj => :nuget,
        Spandx::Dotnet::Parsers::PackagesConfig => :nuget,
        Spandx::Dotnet::Parsers::Sln => :nuget,
        Spandx::Java::Parsers::Maven => :maven,
        Spandx::Js::Parsers::Npm => :npm,
        Spandx::Js::Parsers::Yarn => :yarn,
        Spandx::Php::Parsers::Composer => :composer,
        Spandx::Python::Parsers::PipfileLock => :pypi,
        Spandx::Ruby::Parsers::GemfileLock => :rubygems,
        Spandx::Os::Parsers::Apk => :apk,
      }.freeze
      attr_reader :path, :name, :version, :licenses, :meta

      def initialize(name:, version:, path:, meta: {})
        @path = Pathname.new(path).realpath
        @name = name || @path.basename.to_s
        @version = version || @path.mtime.to_i.to_s
        @licenses = []
        @meta = meta
      end

      def package_manager
        PACKAGE_MANAGERS[Parser.for(path).class]
      end

      def <=>(other)
        return 1 if other.nil?

        score = (name <=> other.name)
        score = score.zero? ? (version <=> other&.version) : score
        score.zero? ? (path.to_s <=> other&.path.to_s) : score
      end

      def hash
        to_s.hash
      end

      def ==(other)
        eql?(other)
      end

      def eql?(other)
        to_s == other.to_s
      end

      def to_s
        @to_s ||= [name, version, path].compact.join(' ')
      end

      def inspect
        "#<#{self.class} name=#{name} version=#{version} path=#{relative_path}>"
      end

      def to_a
        [name, version, license_expression, relative_path.to_s]
      end

      def to_h
        {
          name: name,
          version: version,
          licenses: license_expression,
          path: relative_path.to_s
        }
      end

      private

      def relative_path(from: Pathname.pwd)
        path.relative_path_from(from)
      end

      def license_expression
        licenses.map(&:id).join(' AND ')
      end
    end
  end
end
