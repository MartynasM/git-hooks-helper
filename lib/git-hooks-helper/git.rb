module GitHooksHelper
  class Git
    class << self
      FILES_TO_WATCH = /(.+\.(e?rb|task|rake|thor|prawn|haml|coffee)|[Rr]akefile|[Tt]horfile)/

      def in_index
        #`git diff-index --name-only --cached HEAD`.split("\n").select{ |file| file =~ FILES_TO_WATCH }.map(&:chomp)
        `git diff --cached --name-only --diff-filter=AM HEAD`.split("\n").map(&:chomp).select{|file| file =~ FILES_TO_WATCH}
      end
    end
  end
end