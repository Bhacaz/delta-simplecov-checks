# frozen_string_literal: true

module DeltaSimplecovChecks
  class CLI

    # SECRET_KEY: ${{ secrets.SECRET_KEY }}
    # GITHUB_APP_ID: ${{ secrets.APP_ID }}
    # GITHUB_APP_INSTALLATION_ID: ${{ secrets.APP_INSTALLATION_ID }}
    # GIT_COMMIT: ${{ github.sha }}
    # REPOSITORY: ${{ github.repository }}

    def initialize
      @args = Hash[ARGV.each_slice(2).to_a]
      @@sha = @args['--sha'] || '6605fdee412dc768bd106c5c62cf90ddca6b0f23'
      @@repository = @args['--repository'] || 'Bhacaz/bright_serializer'
      @@coverage_path = @args['--coverage_path'] || 'coverage/.resultset.json'
      @@minimum_delta = @args['--minimum_delta'].to_i || 80
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
