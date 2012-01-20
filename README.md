#!/usr/bin/env ruby

require "git-hooks-helper"

GitHooksHelper.results do
  do_not_stop_on_warnings

  check_ruby_syntax
  check_erb
  check_best_practices
  warning_on "WTF?", "binding.pry", "<<<<<<<"
  warning_on "console.log", "debugger", {:in => [:js]}

  info "Run rspec tests and have a nice day."
end