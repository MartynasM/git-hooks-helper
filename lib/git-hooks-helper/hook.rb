require 'git-hooks-helper/result'
require 'git-hooks-helper/git'
require 'git-hooks-helper/ruby'
require 'git-hooks-helper/extensions/string'
require 'open3'
require 'pry'

module GitHooksHelper
  class Hook

    RB_REGEXP = /\.(rb|rake|task|prawn|[Rr]akefile|task)\z/.freeze
    ERB_REGEXP  = /\.erb\z/.freeze
    JS_REGEXP = /\.js\z/.freeze
    HAML_REGEXP = /\.haml\z/.freeze
    COFFEE_REGEXP = /\.coffee\z/.freeze
    SLIM_REGEXP = /\.slim\z/.freeze

    FILETYPES = {
      rb:     RB_REGEXP,
      erb:    ERB_REGEXP,
      js:     JS_REGEXP,
      haml:   HAML_REGEXP,
      coffee: COFFEE_REGEXP,
      slim:   SLIM_REGEXP
    }.freeze

    RB_WARNING_REGEXP  = /[0-9]+:\s+warning:/.freeze
    HAML_INVALID_REGEXP = /error/.freeze
    ERB_INVALID_REGEXP = /invalid\z/.freeze
    SLIM_INVALID_REGEXP = /Slim::Parser/.freeze
    COLOR_REGEXP = /\e\[(\d+)m/.freeze

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
      filetypes = Array(filetypes)
      if @result.continue?
        debug("Can continue")
        changed_files(filetypes).each do |file|
          yield file
        end
      else
        debug("Cannot continue")
      end
    end

    def changed_files(filetypes = [:all])
      filetypes = Array(filetypes)
       @changed_files.select{ |file| file_matches_filetypes?(file, filetypes) and File.readable?(file) }
    end

    def file_matches_filetypes?(file, filetypes)
      filetypes.any? do |type|
        file =~ FILETYPES[type] || type == :all
      end
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
          lines = stdout.read.split("\n")
          errors = lines.map do |line|
            if line.gsub(COLOR_REGEXP, '') =~ ERB_INVALID_REGEXP
              "#{file} => invalid ERB syntax"
            end
          end.compact
          @result.errors.concat errors
        end
      end
    end

    def check_slim
      each_changed_file([:slim]) do |file|
        Open3.popen3("slimrb -c #{file}") do |stdin, stdout, stderr|
          lines = stderr.read.split("\n")
          # HELP NEEDED HERE.
          # Somewhy this appears in stderr when runnin in read world:
          # 'fatal: Not a git repository: '.git''
          errors = if lines.size > 0 && lines.any?{|line| line =~ SLIM_INVALID_REGEXP}
            # skip last 2 lines from output. There is only trace info.
            @result.errors << "#{file} => invalid SLIM syntax\n  " + lines[0..-3].join("\n  ")
          end
        end
      end
    end

    def check_haml
      each_changed_file([:haml]) do |file|
        Open3.popen3("haml --check #{file}") do |stdin, stdout, stderr|
          lines = stderr.read.split("\n")
          errors = lines.map do |line|
            if line.gsub(COLOR_REGEXP, '') =~ HAML_INVALID_REGEXP
              "#{file} => invalid HAML syntax\n  #{line}"
            end
          end.compact
          @result.errors.concat errors
        end
      end
    end

    def check_best_practices
      Open3.popen3("pwd") do |stdin, stdout, stderr|
        puts stdout.read
      end
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

    def flog_methods(threshold = 20)
      files = changed_files(:rb).join(' ')
      if files != ''
        Open3.popen3("flog -m #{files}") do |stdin, stdout, stderr|
          punishment = stdout.read.split("\n")[3..-1]
          punishment.each do |line|
            line   = line.split(" ")
            score  = line[0].to_f
            method = line[1].strip
            path   = line[2].strip
            if score >= threshold
              @result.warn("Flog for #{method} in #{path} returned #{score}")
            else
              break
            end
          end
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
