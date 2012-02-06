module GitHooksHelper
  class Git
    class << self
      FILES_TO_WATCH = /(.+\.(e?rb|task|rake|thor|prawn)|[Rr]akefile|[Tt]horfile)/

      def in_index
        #`git diff-index --name-only --cached HEAD`.split("\n").select{ |file| file =~ FILES_TO_WATCH }.map(&:chomp)
        `git diff --cached --name-only --diff-filter=AM HEAD`.split("\n").map(&:chomp)
      end
    end
  end
end