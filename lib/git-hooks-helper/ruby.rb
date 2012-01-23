module GitHooksHelper
  class Ruby
    def self.check_syntax(file)
      @compiler_ruby = `which ruby`.strip
      "#{@compiler_ruby} -wc #{file}"
    end
  end
end