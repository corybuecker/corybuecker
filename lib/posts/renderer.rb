# frozen_string_literal: true

class Posts
  class Renderer
    def self.render(document:)
      new(document:).render
    end

    def initialize(document:)
      @document = document
    end

    def render(extras = {})
      Liquid::Template.parse(File.read('templates/default.liquid'))
                      .render(extras.merge({ 'post' => document.to_liquid }), { strict_variables: true })
    end

    attr_reader :document
  end
end
