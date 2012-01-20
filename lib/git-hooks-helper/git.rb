module GitHooksHelper
  class Git
    class << self
      FILES_TO_WATCH = /(.+\.(e?rb|task|rake|thor|prawn)|[Rr]akefile|[Tt]horfile)/

      def in_index
        `git diff-index --name-only --cached HEAD`.split("\n").select{ |file| file =~ FILES_TO_WATCH }.map(&:chomp)
      end
    end
  end
end