# frozen_string_literal: true

class Posts
  class Lister
    def self.posts_list
      new.posts_list
    end

    def self.homepage
      new.homepage
    end

    def self.posts
      new.posts
    end

    def initialize; end

    def homepage
      list.last
    end

    def posts
      list
    end

    def posts_list
      (list - [homepage]).reverse
    end

    private

    def list
      Dir.glob('content/*.md')
    end
  end
end
