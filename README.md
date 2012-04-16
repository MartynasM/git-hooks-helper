Instalation
-----------
  gem install git-hooks-helper

File clasification
------------------

Most commands use file classes internally or accept type class as a param.
File type classes and associated file extensions:

1. :rb  - .rb .rake .task .prawn
2. :js  - .js
3. :erb - .erb

Usage
-----
Create your hit hook in .git/hooks directory and make it executable.

My example pre-commit hook that i use myself.
To create such a hook type in console:

  cd your/project/
  touch .git/hooks/pre-commit
  chmod +x .git/hooks/pre-commit
  vim .git/hooks/pre-commit

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
    check_ruby_syntax                                    # errors when ruby syntax has errors
    check_erb                                            # errors when ERB syntax has errors
    check_best_practices                                 # warnings when ruby best practices are violated
    warning_on "WTF?", "binding.pry", "<<<<<<<"          # warnings when any of these texts are present in any commited files
    warning_on "console.log", "debugger", {:in => [:js]} # warning when any of these texts are present in JS files

    # messages
    info   "Run rspec tests and have a nice day."        # Green text
    notice "Or bad things will happen"                   # Yellow text
    warn   "Cthulhu"                                     # Red text
  end
```