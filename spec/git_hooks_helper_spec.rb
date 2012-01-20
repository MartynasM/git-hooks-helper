require 'spec_helper'

describe GitHooksHelper do

  it "should run empty hook" do
    GitHooksHelper::Git.should_receive(:in_index).and_return([])

    begin
      GitHooksHelper.results do
      end
    rescue SystemExit
      $!.status.should eql 0
    end
  end

  describe "check_ruby_syntax" do
    before(:each) do
      @files = [
        "spec/git_files/bad_syntax.rb",
        "spec/git_files/good_syntax.rb"
      ]
    end

    it "should fail on bad rb syntax" do
      GitHooksHelper::Git.should_receive(:in_index).and_return(@files)
      begin
        GitHooksHelper.results do
          check_ruby_syntax
        end
      rescue SystemExit => e
        $!.status.should eql 1
      end
    end

    it "should pass good rb syntax" do
      GitHooksHelper::Git.should_receive(:in_index).and_return(["spec/git_files/good_syntax.rb"])
      begin
        GitHooksHelper.results do
          check_ruby_syntax
        end
      rescue SystemExit => e
        $!.status.should eql 0
      end
    end
  end

  describe "never_stop" do
    it "should pass even on errors and warnings" do
      GitHooksHelper::Git.should_receive(:in_index).and_return(["spec/git_files/bad_syntax.rb"])
      begin
        GitHooksHelper.results do
          never_stop
          check_ruby_syntax
        end
      rescue SystemExit => e
        $!.status.should eql 0
      end
    end
  end

  describe "stop_on_warnings" do # also sort of checks best practices
    it "should stop even on warnings" do
      GitHooksHelper::Git.should_receive(:in_index).and_return(["spec/git_files/no_best_practices.rb"])
      begin
        GitHooksHelper.results do
          stop_on_warnings
          check_best_practices
        end
      rescue SystemExit => e
        $!.status.should eql 1
      end
    end

    it "should run OK when no errors" do
      GitHooksHelper::Git.should_receive(:in_index).and_return(["spec/git_files/ok_best_practices.rb"])
      begin
        GitHooksHelper.results do
          stop_on_warnings
          check_best_practices
        end
      rescue SystemExit => e
        $!.status.should eql 0
      end
    end
  end

  describe "check_erb" do
    it "should stop even on warnings on syntax error in ERB" do
      GitHooksHelper::Git.should_receive(:in_index).and_return(["spec/git_files/syntax_error.html.erb"])
      begin
        GitHooksHelper.results do
          stop_on_warnings
          check_erb
        end
      rescue SystemExit => e
        $!.status.should eql 1
      end
    end

    it "should show no error on correct ERB" do
      GitHooksHelper::Git.should_receive(:in_index).and_return(["spec/git_files/ok.html.erb"])
      begin
        GitHooksHelper.results do
          stop_on_warnings
          check_erb
        end
      rescue SystemExit => e
        $!.status.should eql 0
      end
    end
  end

  describe "warning_on" do
    it "should show error when file contains specific text" do
      GitHooksHelper::Git.should_receive(:in_index).and_return(["spec/git_files/ok.html.erb"])
      begin
        GitHooksHelper.results do
          stop_on_warnings
          check_erb 
        end
      rescue SystemExit => e
        $!.status.should eql 0
      end
    end
  end

end