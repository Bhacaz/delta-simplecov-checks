# frozen_string_literal: true

module DeltaSimplecovChecks
  class FileDiff

    attr_accessor :filename, :missing_lines, :coverage, :added_lines

    def initialize(filename)
      @filename = filename
      @added_lines = []
      @missing_lines = []
    end

    def file_content
      @file_content ||= File.read(filename).split("\n")
    end

    def missing_lines_to_md(lines)
      md = +"Missing lines\n```ruby\n"
      file_content[(lines.first - 1)..(lines.last - 1)].zip((lines.first..lines.last ).to_a) do |content, line_number|
        md << "#{line_number} #{content}\n"
      end
      md << "```\n"
      md
    end
  end
end
