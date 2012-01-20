require "git-hooks-helper/hook"

module GitHooksHelper
  def self.results(&block)
    GitHooksHelper::Hook.new(&block)
  end
end