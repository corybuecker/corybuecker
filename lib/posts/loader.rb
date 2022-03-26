# frozen_string_literal: true

class Posts
  class Loader
    def self.load(path:)
      new(path:)
    end

    def initialize(path:)
      @path = path
    end

    def to_document
      Posts::Document.new(content:, frontmatter:)
    end

    private

    attr_reader :path

    def frontmatter
      YAML.load(parts.first.strip).map { [_1.to_sym, _2] }.to_h
    end

    def content
      parts.last.strip
    end

    def parts
      @parts ||= File.read(path).split('---', 3).select { _1.strip.length.positive? }
    end
  end
end
