# frozen_string_literal: true

require 'fileutils'
require 'logger'
module Assets
  class Copier
    def self.copy
      new.copy
    end

    def initialize
      @mappings = Fingerprinter.fingerprint
      @logger = Logger.new($stdout)
    end

    def copy
      copy_static
      mappings.each { |source, destination| File.rename "output/#{source}", "output/#{destination}" }
    end

    private

    attr_reader :mappings, :logger

    def copy_static
      FileUtils.cp_r 'assets/static/.', 'output'
    end
  end
end
