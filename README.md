Instalation
-----------
  gem install git-hooks-helper

Dependencies
------------
This gem has no dependencies and it will be up to you to provide required and possible dependencies.
Possible dependencies are tied to checks you want to use:
 * check_erb - gem install rails-erb-check
 * check_slim - gem install slim
 * check_haml - gem install haml
 * check_best_practices - gem install rails_best_practices

File clasification
------------------

Most commands use file classes internally or accept type class as a param.
File type classes and associated file extensions:

1. :rb   - .rb .rake .task .prawn
2. :js   - .js
3. :erb  - .erb
3. :slim - .slim

Usage
-----
Create your hit hook in .git/hooks directory and make it executable.

My example pre-commit hook that i use myself.
To create such a hook type in console:
```
  cd your/project/
  touch .git/hooks/pre-commit
  chmod +x .git/hooks/pre-commit
  vim .git/hooks/pre-commit
```
and paste following code:


```ruby
  #!/usr/bin/env ruby

  require "git-hooks-helper"

  GitHooksHelper.results do
    # fail/pass options
    # stop_on_warnings                                   # makes git commit fail if any warnings are found
    # never_stop                                         # hooks never fails commits
    # list_files                                         # shows list of all changed files

    # checks
    check_ruby_syntax                                    # errors when ruby syntax is invalid
    check_erb                                            # errors when ERB syntax is invalid
    check_slim                                           # errors when SLIM syntax is invalid
    check_haml                                           # errors when HAML syntax is invalid
    check_best_practices                                 # warnings when ruby best practices are violated
    warning_on "WTF?", "binding.pry", "<<<<<<<"          # warnings when any of these texts are present in any commited files
    warning_on "console.log", "debugger", {:in => [:js]} # warning when any of these texts are present in JS files

    # messages
    info   "Run rspec tests and have a nice day."        # Green text
    notice "Or bad things will happen"                   # Yellow text
    warn   "Cthulhu"                                     # Red text
  end
```

Badges
------
[![Code Climate](https://codeclimate.com/github/MartynasM/git-hooks-helper.png)](https://codeclimate.com/github/MartynasM/git-hooks-helper)
