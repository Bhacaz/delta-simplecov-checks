# frozen_string_literal: true

require 'json'

module DeltaSimplecovChecks
  class GitDiffParser

    attr_accessor :files_diff, :total_coverage, :delta

    def initialize
      @files_diff = []
      extract_delta
      @total_coverage = total_coverage
      calculate_delta_coverage
    end

    def mean(array)
      array.sum.to_f / array.length
    end

    def extract_delta
      git_diff = File.read('coverage/diff.txt')
      # git_diff = `git diff origin/master.. --no-color -U0`

      git_diff.split("\n").each do |line|
        if line.start_with?('diff --git a/')
          filename = line.scan(/diff --git a\/(.+)\s/)[0].first
          @files_diff << FileDiff.new(filename)
        elsif line.start_with?('@@')
          current_file_diff = @files_diff.last
          first_line_add = line.scan(/@@ -.+\+(.+?) @@/)[0].first
          first_line, number_added = first_line_add.split(',')
          first_line = first_line.to_i
          number_added = number_added&.to_i
          current_file_diff.added_lines << (number_added ? (first_line..first_line + number_added - 1).to_a : [first_line])
        end
      end
    end

    def coverage_results
      @coverage_results ||= JSON.parse(File.read(DeltaSimplecovChecks::CLI.coverage_path)).first.last['coverage']
    end

    def total_coverage
      coverage_each_file = []
      coverage_results.each do |_filename, coverage_by_line|
        lines = coverage_by_line['lines'].dup
        lines.compact!
        total = lines.size
        with_coverage = lines.count(&:positive?)
        coverage_each_file << with_coverage.to_f / total * 100
      end
      mean(coverage_each_file)
    end

    def calculate_delta_coverage
      filenames = coverage_results.keys
      @files_diff.delete_if { |f| filenames.none? { |filename| filename.end_with?(f.filename) } }
      coverage_results.each do |filename, coverage_by_line|
        file_diff = @files_diff.detect { |f| filename.end_with?(f.filename) }
        next unless file_diff

        coverage_by_line = coverage_by_line['lines']
        covered_lines = 0
        relevant_lines = file_diff.added_lines.flatten.size
        file_diff.missing_lines = []

        file_diff.added_lines.each do |line_batch|
          missing_lines = []
          line_batch.each do |line_number|
            covered = coverage_by_line[line_number - 1]
            if covered.nil?
              relevant_lines -= 1
            elsif covered.positive?
              covered_lines += 1
            else
              missing_lines << line_number
            end
          end
          file_diff.missing_lines << missing_lines if missing_lines.any?
        end
        file_diff.coverage = covered_lines.to_f / relevant_lines * 100
      end
      @delta = mean(@files_diff.map(&:coverage))
    end
  end
end

# params[:service] = 'jenkins'
# params[:branch] = ENV['ghprbSourceBranch'] || ENV['GIT_BRANCH']
# params[:commit] = ENV['ghprbActualCommit'] || ENV['GIT_COMMIT']
# params[:pr] = ENV['ghprbPullId']
# params[:build] = ENV['BUILD_NUMBER']
# params[:root] = ENV['WORKSPACE']
# params[:build_url] = ENV['BUILD_URL']

# data = SimplecovDelta.extract_delta
# delta_coverage = SimplecovDelta.calculate_delta_coverage(data)
# GithubApp.new(delta_coverage).post_check
