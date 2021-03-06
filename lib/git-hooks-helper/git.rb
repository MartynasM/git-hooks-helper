module GitHooksHelper
  class Git
    class << self
      FILES_TO_WATCH = /(.+\.(e?rb|js|rake|prawn|haml|coffee|slim|task)|[Rr]akefile)/

      def in_index
        all_files = `git diff --cached --name-only --diff-filter=AM HEAD`.split("\n").map(&:chomp)
        all_files.select{|file| file =~ FILES_TO_WATCH}
      end
    end
  end
end