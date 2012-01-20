require "git-hooks-helper/result"
require "git-hooks-helper/git"
require "git-hooks-helper/extensions/string"
require "open3"

module GitHooksHelper
  class Hook

    RB_REGEXP     = /\.(rb|rake|task|prawn)\z/
    ERB_REGEXP   = /\.erb\z/
    JS_REGEXP   = /\.js\z/

    RB_WARNING_REGEXP  = /[0-9]+:\s+warning:/
    ERB_INVALID_REGEXP = /invalid\z/
    COLOR_REGEXP = /\e\[(\d+)m/

    # Set this to true if you want warnings to stop your commit
    def initialize(&block)
      @compiler_ruby = `which ruby`.strip

      @result = GitHooksHelper::Result.new(false)
      @changed_ruby_files = GitHooksHelper::Git.in_index

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
      each_changed_file(filetypes) do |file|
        puts file
      end
    end

    def each_changed_file(filetypes = [:all])
      if @result.continue?
        @changed_ruby_files.each do |file|
          unless filetypes.include?(:all)
            next unless (filetypes.include?(:rb) and file =~ RB_REGEXP) or (filetypes.include?(:erb) and file =~ ERB_REGEXP) or (filetypes.include?(:js) and file =~ JS_REGEXP)
          end
          yield file if File.readable?(file)
        end
      end
    end

    def check_ruby_syntax
      each_changed_file([:rb]) do |file|
        Open3.popen3("#{@compiler_ruby} -wc #{file}") do |stdin, stdout, stderr|
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

    def check_best_practices
      each_changed_file([:rb, :erb]) do |file|
        puts "bundle exec rails_best_practices --spec --test #{file}"
        Open3.popen3("bundle exec rails_best_practices --spec --test #{file}") do |stdin, stdout, stderr|
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

  end
end