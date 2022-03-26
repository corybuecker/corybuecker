# frozen_string_literal: true

class Posts
  module Filters
    def asset(input)
      assets[input][:path]
    end

    def integrity(input)
      assets[input][:integrity]
    end

    def assets
      @assets ||= Assets::Fingerprinter.integrity
    end
  end
end
