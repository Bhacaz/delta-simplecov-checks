# frozen_string_literal: true

require 'openssl'
require 'uri'
require 'net/http'
require 'time'
require 'base64'
require 'jwt'

module DeltaSimplecovChecks
  class Checks
    def initialize(git_diff_data)
      @git_diff_data = git_diff_data
    end

    class << self
      def build_app_jwt
        payload = {
          # issued at time
          iat: Time.now.to_i,
          # JWT expiration time (10 minute maximum)
          exp: Time.now.to_i + (10 * 60),
          # GitHub App's identifier
          iss: find_app_id
        }

        JWT.encode(payload, OpenSSL::PKey::RSA.new(ENV['APP_SECRET']), "RS256")
      end

      def find_app_id
        uri = URI.parse("https://api.github.com/app/installations")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        req = Net::HTTP::Get.new(uri.request_uri, { 'Authorization' => "Bearer #{build_app_jwt}", 'Accept' => 'application/vnd.github.v3+json'})
        res = http.request(req)

        user = DeltaSimplecovChecks::CLI.repository.split('/').first
        JSON.parse(res.body).each do |installation|
          return installation['id'] if installation['account']['login'] == user
        end
      end

      def get_app_access_token
        uri = URI.parse("https://api.github.com/app/installations/#{find_app_id}/access_tokens")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        req = Net::HTTP::Post.new(uri.request_uri, { 'Authorization' => "Bearer #{build_app_jwt}" })
        res = http.request(req)
        JSON.parse(res.body)['token']
      end
    end

    def build_checks_body
      conclusion = @git_diff_data.delta >= DeltaSimplecovChecks::CLI.minimum_delta ? 'success' : 'failure'
      {
        name: "Delta Coverage",
        head_sha: ENV['ghprbActualCommit'] || DeltaSimplecovChecks::CLI.sha,
        status: "completed",
        completed_at: Time.now.utc.iso8601,
        conclusion: conclusion,
        output: build_output
      }
    end

    def build_output_text
      md = +''

      @git_diff_data.files_diff.each do |file_diff|
        md << "### #{file_diff.coverage.round(2)}% - #{file_diff.filename}\n"
        md << file_diff.missing_lines.map { |lines| file_diff.missing_lines_to_md(lines) }.join("\n")
      end
      md
    end

    def build_annotations
      @git_diff_data.files_diff.flat_map do |file_diff|
        file_diff.missing_lines.select(&:any?).map do |batch_lines|
          {
            path: file_diff.filename,
            start_line: batch_lines.first,
            end_line: batch_lines.last,
            annotation_level: 'warning',
            message: "Change not tested. Lines: #{batch_lines.join(', ')}",
            title: 'Delta Coverage'
          }
        end
      end
    end

    def post_with_serverless
      uri = URI.parse('https://simplecov-checks-handler.vercel.app/api/simplecov_checks')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      req = Net::HTTP::Post.new(uri.request_uri)
      req.body = { repository: DeltaSimplecovChecks::CLI.repository, body: build_checks_body }.to_json
      http.request(req)
    end

    def build_output
      {
        title: "Branch coverage: #{@git_diff_data.delta.round(2)}%",
        summary: "Total coverage: #{@git_diff_data.total_coverage.round(2)}%\nBranch coverage must be ≥ #{DeltaSimplecovChecks::CLI.minimum_delta}%",
        text: build_output_text,
        annotations: build_annotations
      }
    end

    def post_check(repository: DeltaSimplecovChecks::CLI.repository, body: build_checks_body.to_json)
      uri = URI.parse("https://api.github.com/repos/#{repository}/check-runs")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      req = Net::HTTP::Post.new(uri.request_uri, { 'Authorization' => "token #{self.class.get_app_access_token}", 'Accept' => 'application/vnd.github.antiope-preview+json' })
      req.body = body
      http.request(req)
    end
  end
end
