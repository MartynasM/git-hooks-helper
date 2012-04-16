# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "git-hooks-helper/version"

Gem::Specification.new do |s|
  s.name        = "git-hooks-helper"
  s.version     = GitHooksHelper::VERSION
  s.authors     = ["Martynas Margis"]
  s.email       = ["no@email.com"]
  s.homepage    = "https://github.com/BuGo/git-hooks-helper"
  s.summary     = %q{Small gem to help write simple git hooks}
  s.description = %q{Gem for creating simple git hooks in ruby.}

  s.rubyforge_project = "git-hooks-helper"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
#  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # s.add_runtime_dependency "open3"
end
