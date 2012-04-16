require "git-hooks-helper/result"
require "git-hooks-helper/git"
require "git-hooks-helper/ruby"
require "git-hooks-helper/extensions/string"
require "open3"

module GitHooksHelper
  class Hook

    FILETYPES = {
      rb:     RB_REGEXP,
      erb:    ERB_REGEXP,
      js:     JS_REGEXP,
      haml:   HAML_REGEXP,
      coffee: COFFEE_REGEXP
    }

    RB_WARNING_REGEXP  = /[0-9]+:\s+warning:/
    HAML_INVALID_REGEXP = /error/
    ERB_INVALID_REGEXP = /invalid\z/
    COLOR_REGEXP = /\e\[(\d+)m/

    # Set this to true if you want warnings to stop your commit
    def initialize(&block)
      @ruby = GitHooksHelper::Ruby.new
      @debug = false

      @result = GitHooksHelper::Result.new(false)
      @changed_files = GitHooksHelper::Git.in_index
      debug("changed files")
      debug @changed_files
      instance_eval(&block) if block

      if @result.errors?
        status = 1
        puts "ERRORS:".red
        puts @result.errors.join("\n")
        puts "--------\n".red
      end

      if @result.warnings?
        if @result.stop_on_warnings
          puts "WARNINGS:".yellow
        else
          puts "Warnings:".yellow
        end
        puts @result.warnings.join("\n")
        puts "--------\n".yellow
      end

      if @result.perfect_commit?
        puts "Perfect commit!".green
      end

      if @result.continue?
        # all good
        puts("COMMIT OK:".green)
        exit 0
      else
        puts("COMMIT FAILED".red)
        exit 1
      end
    end

    def start_debug
      @debug = true
    end

    def stop_debug
      @debug = false
    end

    def stop_on_warnings
      @result.stop_on_warnings = true
    end

    def do_not_stop_on_warnings
      @result.stop_on_warnings = false
    end

    def never_stop
      @result.never_stop = true
    end

    def list_files(filetypes = [:all])
      puts "--- Listing files of type: #{filetypes}"
      each_changed_file(filetypes) do |file|
        puts file
      end
      puts "--- End of list"
    end

    def each_changed_file(filetypes = [:all])
      filetypes = [filetypes] unless filetypes.class == Array
      if @result.continue?
        debug("Can continue")
        @changed_files.each do |file|
          next unless file_matches_filetypes?(file, filetypes)
          yield file if File.readable?(file)
        end
      else
        debug("Cannot continue")
      end
    end

    def file_matches_filetypes?(file, filetypes)
      return true if filetypes.include?(:all)
      filetypes.each do |type|
        return true if file =~ FILETYPES[type]
      end
      return false
    end

    def check_ruby_syntax
      each_changed_file([:rb]) do |file|
        Open3.popen3(GitHooksHelper::Ruby.check_syntax(file)) do |stdin, stdout, stderr|
          stderr.read.split("\n").each do |line|
            line =~ RB_WARNING_REGEXP ? @result.warnings << line : @result.errors << line
          end
        end
      end
    end

    def check_erb
      each_changed_file([:erb]) do |file|
        Open3.popen3("rails-erb-check #{file}") do |stdin, stdout, stderr|
          @result.errors.concat stdout.read.split("\n").map{|line| "#{file} => invalid ERB syntax" if line.gsub(COLOR_REGEXP, '') =~ ERB_INVALID_REGEXP}.compact
        end
      end
    end

    def check_haml
      each_changed_file([:haml]) do |file|
        popen3("haml --check #{file}") do |stdin, stdout, stderr|
          @result.errors.concat stderr.read.split("\n").map{|line| "#{file} => invalid HAML syntax\n#{line}" if line.gsub(COLOR_REGEXP, '') =~ HAML_INVALID_REGEXP}.compact
        end
      end
    end

    def check_best_practices
      each_changed_file([:rb, :erb, :haml]) do |file|
        Open3.popen3("rails_best_practices --spec --test #{file}") do |stdin, stdout, stderr|
          @result.warn(stdout.read.split("\n").map do |line|
            if line =~ /#{file}/
              line.gsub(COLOR_REGEXP, '').strip
            end
          end.compact)
        end
      end
    end

    # Maybe need options for different file types :rb :erb :js
    def warning_on(*args)
      options = (args[-1].kind_of?(Hash) ? args.pop : {})
      each_changed_file(options[:in] || [:all]) do |file|
        Open3.popen3("fgrep -nH \"#{args.join("\n")}\" #{file}") do |stdin, stdout, stderr|
          err = stdout.read
          err.split("\n").each do |msg|
            args.each do |string|
              @result.warn("#{msg.split(" ").first} contains #{string}") if msg =~ /#{string}/
            end
          end
        end
      end
    end

    def info(text)
      puts(text.green)
    end

    def notice(text)
      puts(text.yellow)
    end

    def warn(text)
      puts(text.red)
    end

    def debug(msg)
      puts msg if @debug
    end

  end
end