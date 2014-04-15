require 'rubygems'
require 'bundler/setup'

require 'git-hooks-helper'

RSpec.configure do |config|
  config.before(:all) do
    # Redirect stderr and stdout
    sio = StringIO.new
    $stderr = sio
    $stdout = sio
    # $stderr = File.new(File.join(File.dirname(__FILE__), 'dev', 'null.txt'), 'w')
    # $stdout = File.new(File.join(File.dirname(__FILE__), 'dev', 'null.txt'), 'w')
  end
  config.after(:all) do
    $stderr = STDERR
    $stdout = STDOUT
  end
end

def clear_screen
  $stdout.truncate(0)
end

def get_screen
  $stdout.string.gsub("\u0000", '')
end

def in_screen(string)
  expect(get_screen).to include(string)
end

def not_in_screen(string)
  expect(get_screen).not_to include(string)
end

{ perfect_commit: "Perfect commit!", error: "ERRORS", warning: 'Warnings'}.each do |method, message|
  define_method(:"see_#{method}") do
    in_screen(message)
  end

  define_method(:"not_see_#{method}") do
    not_in_screen(message)
  end
end

def hook_passes(e)
  expect(e.status).to eql 0
end

def hook_fails(e)
  in_screen('COMMIT FAILED')
  expect(e.status).to eql 1
end

def positinve_ending(e)
  not_see_error
  not_see_warning
  see_perfect_commit
  hook_passes(e)
end
