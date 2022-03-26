# frozen_string_literal: true

module Assets
  class Lister
    def self.list
      new.list
    end

    def initialize; end

    def list
      # TODO: a true glob with removal of chunks.
      Dir.glob('css/*', base: 'output') + Dir.glob('js/{highlight,analytics}.js', base: 'output')
    end
  end
end
