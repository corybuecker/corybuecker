# frozen_string_literal: true

require 'logger'
require 'fileutils'

class Posts
  def self.build_posts
    new.build_posts
  end

  def self.build_homepage
    new.build_homepage
  end

  def initialize
    @logger = Logger.new($stdout)
    setup_liquid
  end

  def build_homepage
    other_posts = Lister.posts_list.map do |path|
      doc = Loader.new(path: path).to_document
      { "url" => "/posts/#{doc.slug}", "title" => doc.title }
    end

    doc = Loader.new(path: Lister.homepage).to_document
    html = Renderer.new(document: doc).render({ 'posts' => other_posts })

    File.open('output/index.html', 'w+') { _1.write(html) }
  end

  def build_posts
    FileUtils.mkdir_p 'output/posts'

    Lister.posts.map do |path|
      doc = Loader.new(path:).to_document
      html = Renderer.render(document: doc)

      File.open("output/posts/#{doc.slug}/index.html", 'w+') { _1.write(html) }
    end
  end

  private

  attr_reader :logger

  def setup_liquid
    Liquid::Template.file_system = Liquid::LocalFileSystem.new('./templates')
    Liquid::Template.error_mode = :strict
    Liquid::Template.register_filter(Posts::Filters)
  end
end
