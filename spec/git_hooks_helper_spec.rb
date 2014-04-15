require 'spec_helper'

describe GitHooksHelper do
  before(:each) { clear_screen }

  it 'should run empty hook' do
    GitHooksHelper::Git.should_receive(:in_index).and_return([])

    expect do
      GitHooksHelper.results do
      end
    end.to(raise_exception(SystemExit) do |e|
      positinve_ending(e)
    end)
  end

  describe '#info' do
    it 'should output simple text' do
      expect do
        GitHooksHelper.results do
          info 'Test info text'
        end
      end.to(raise_exception(SystemExit) do |e|
        positinve_ending(e)
        in_screen("[1m\e[32mTest info text") # green
      end)
    end
  end

  describe '#notice' do
    it 'should output simple text' do
      expect do
        GitHooksHelper.results do
          notice 'Test info text'
        end
      end.to(raise_exception(SystemExit) do |e|
        positinve_ending(e)
        in_screen("[1m\e[33mTest info text") # yellow
      end)
    end
  end

  describe '#info' do
    it 'should output simple text' do
      expect do
        GitHooksHelper.results do
          warn 'Test info text'
        end
      end.to(raise_exception(SystemExit) do |e|
        positinve_ending(e)
        in_screen("[1m\e[31mTest info text") # red
      end)
    end
  end


  describe 'check_ruby_syntax' do
    before(:each) do
      @files = [
        'spec/git_files/bad_syntax.rb',
        'spec/git_files/good_syntax.rb'
      ]
    end

    it 'should fail on bad rb syntax' do
      GitHooksHelper::Git.should_receive(:in_index).and_return(@files)
      expect do
        GitHooksHelper.results do
          check_ruby_syntax
        end
      end.to(raise_exception(SystemExit) do |e|
        hook_fails(e)
        not_see_perfect_commit
        see_warning
        in_screen("spec/git_files/bad_syntax.rb:4: syntax error, unexpected end-of-input, expecting keyword_end")
        in_screen("spec/git_files/bad_syntax.rb:4: warning: mismatched indentations at 'end' with 'def' at 2")
      end)
    end

    it 'should pass good rb syntax' do
      GitHooksHelper::Git.should_receive(:in_index).and_return(['spec/git_files/good_syntax.rb'])
      expect do
        GitHooksHelper.results do
          check_ruby_syntax
        end
      end.to(raise_exception(SystemExit) do |e|
        positinve_ending(e)
      end)
    end
  end

  describe 'never_stop' do
    it 'should pass even on errors and warnings' do
      GitHooksHelper::Git.should_receive(:in_index).and_return(['spec/git_files/bad_syntax.rb'])
      expect do
        GitHooksHelper.results do
          never_stop
          check_ruby_syntax
        end
      end.to(raise_exception(SystemExit) do |e|
        see_warning
        hook_passes(e)
      end)
    end
  end

  describe 'stop_on_warnings' do # also sort of checks best practices
    it 'should stop even on warnings' do
      GitHooksHelper::Git.should_receive(:in_index).and_return(['spec/git_files/no_best_practices.rb'])
      expect do
        GitHooksHelper.results do
          stop_on_warnings
          check_best_practices
        end
      end.to(raise_exception(SystemExit) do |e|
        hook_fails(e)
        in_screen("WARNINGS") # special case - upercase when FAIL on warning
        in_screen 'git_files/no_best_practices.rb:2 - remove trailing whitespace'
      end)
    end

    it 'should run OK when no errors' do
      GitHooksHelper::Git.should_receive(:in_index).and_return(['spec/git_files/ok_best_practices.rb'])
      expect do
        GitHooksHelper.results do
          stop_on_warnings
          check_best_practices
        end
      end.to(raise_exception(SystemExit) do |e|
        positinve_ending(e)
      end)
    end
  end

  describe 'check_erb' do
    it 'should stop on syntax error in ERB' do
      GitHooksHelper::Git.should_receive(:in_index).and_return(['spec/git_files/syntax_error.html.erb'])
      expect do
        GitHooksHelper.results do
          stop_on_warnings
          check_erb
        end
      end.to(raise_exception(SystemExit) do |e|
        hook_fails(e)
        see_error
        in_screen('spec/git_files/syntax_error.html.erb => invalid ERB syntax')
      end)
    end

    it 'should show no error on correct ERB' do
      GitHooksHelper::Git.should_receive(:in_index).and_return(['spec/git_files/ok.html.erb'])
      expect do
        GitHooksHelper.results do
          stop_on_warnings
          check_erb
        end
      end.to(raise_exception(SystemExit) do |e|
        positinve_ending(e)
      end)
    end
  end

  describe 'check_slim' do

    it 'should stop on error in SLIM template' do
      GitHooksHelper::Git.should_receive(:in_index).and_return(['spec/git_files/syntax_error.html.slim'])
      expect do
        GitHooksHelper.results do
          stop_on_warnings
          check_slim
        end
      end.to(raise_exception(SystemExit) do |e|
        see_error
        in_screen("spec/git_files/syntax_error.html.slim => invalid SLIM syntax")
        in_screen("Slim::Parser::SyntaxError: Expected closing brace }")
        in_screen("spec/git_files/syntax_error.html.slim, Line 1, Column 25")
        in_screen("div class='\#{@some_class'\n")
        hook_fails(e)
      end)
    end

    it 'should show to error in correct SLIM template' do
      GitHooksHelper::Git.should_receive(:in_index).and_return(['spec/git_files/ok.html.slim'])
      expect do
        GitHooksHelper.results do
          stop_on_warnings
          check_slim
        end
      end.to(raise_exception(SystemExit) do |e|
        positinve_ending(e)
      end)
    end

  end

  describe 'warning_on' do
    it 'should show error when file contains specific text' do
      GitHooksHelper::Git.should_receive(:in_index).and_return(['spec/git_files/ok.html.erb'])
      expect do
        GitHooksHelper.results do
          stop_on_warnings
          check_erb
        end
      end.to(raise_exception(SystemExit) do |e|
        positinve_ending(e)
      end)
    end
  end

  describe 'flog_methods' do
  end

end
