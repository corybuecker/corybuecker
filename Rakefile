# frozen_string_literal: true

require 'logger'

logger = Logger.new($stdout)
logger.level = Logger::INFO

require 'bundler'
Bundler.require(:default)

require './lib/posts'
Dir.glob('lib/**/*.rb') { load _1 }

task :build do
  Posts.build_posts
  Posts.build_homepage

  Assets::Copier.copy
end
