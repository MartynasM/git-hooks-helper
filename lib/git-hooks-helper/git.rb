module GitHooksHelper
  class Git
    class << self
      FILES_TO_WATCH = /(.+\.(e?rb|task|rake|thor|prawn)|[Rr]akefile|[Tt]horfile)/

      def in_index
        #`git diff-index --name-only --cached HEAD`.split("\n").select{ |file| file =~ FILES_TO_WATCH }.map(&:chomp)
        puts FILES_TO_WATCH
        puts "herp.rb" =~ FILES_TO_WATCH
        if "herp.rb" =~ FILES_TO_WATCH
          puts "YES"
        end

        puts puts `git diff-index --name-only --cached HEAD`.split("\n").size
        puts `git diff-index --name-only --cached HEAD`.split("\n").each do |file|
          puts file
          puts file =~ FILES_TO_WATCH
        end
        `git diff --cached --name-only --diff-filter=AM HEAD`.split("\n").select{ |file| file =~ FILES_TO_WATCH }.map(&:chomp)
      end
    end
  end
end