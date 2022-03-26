# frozen_string_literal: true

class Posts
  Document = Struct.new(:content, :frontmatter, keyword_init: true) do
    def initialize(content:, frontmatter:)
      super(content:, frontmatter: Struct.new(*frontmatter.keys, keyword_init: true).new(frontmatter))
    end

    def to_liquid
      {
        'body' => body,
        'title' => title,
        'description' => description,
        'published' => published,
        'revised' => revised
      }
    end

    def description
      frontmatter.description
    end

    def title
      frontmatter.title
    end

    def body
      Kramdown::Document.new(content, input: 'GFM').to_html
    end

    def slug
      frontmatter.slug
    end

    def published
      DateTime.parse(frontmatter.published)
    end

    def revised
      frontmatter.members.include?(:revised) ? DateTime.parse(frontmatter.revised) : ''
    end
  end
end
