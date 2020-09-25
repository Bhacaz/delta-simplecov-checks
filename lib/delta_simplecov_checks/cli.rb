# frozen_string_literal: true

module DeltaSimplecovChecks
  class CLI
    def initialize
      @args = Hash[ARGV.each_slice(2).to_a]
      @@sha = @args['--sha']
      @@repository = @args['--repository']
      @@coverage_path = @args['--coverage_path'] || 'coverage/.resultset.json'
      @@minimum_delta = @args['--minimum_delta'].to_i || 80

      raise ArgumentError 'sha commmit is required (--sha).' unless @@sha
      raise ArgumentError 'repository commmit is required (--repository).' unless @@repository
    end

    def self.sha
      @@sha
    end

    def self.repository
      @@repository
    end

    def self.coverage_path
      @@coverage_path
    end

    def self.minimum_delta
      @@minimum_delta
    end
  end
end
