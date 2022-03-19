# frozen_string_literal: true

require 'logger'
require 'digest'

module Assets
  class Fingerprinter
    def self.fingerprint
      new.fingerprint
    end

    def self.integrity
      new.integrity
    end

    def initialize
      @files = Lister.list
      @logger = Logger.new($stdout)
    end

    def integrity
      files.map { [file(_1), { path: rename(_1), integrity: sha(_1) }] }.to_h
    end

    def fingerprint
      files.map { [_1, rename(_1)] }.to_h
    end

    private

    attr_reader :files, :logger

    def sha(original_file)
      Digest::SHA2.new(256).hexdigest(File.read("output/#{original_file}"))
    end

    def file(original_file)
      File.basename(original_file)
    end

    def rename(original_file)
      logger.debug(original_file)

      sha = Digest::SHA2.new(256).hexdigest(File.read("output/#{original_file}"))
      logger.debug(sha)

      basename = File.basename(original_file, '.*')
      extname = File.extname(original_file)
      dirname = File.dirname(original_file)

      "#{dirname}/#{basename}-#{sha}#{extname}"
    end
  end
end
