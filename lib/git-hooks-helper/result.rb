module GitHooksHelper
  class Result

    attr_accessor :errors, :warnings, :stop_on_warnings, :never_stop

    def initialize(stop_on_warnings)
      @errors = []
      @warnings = []
      @stop_on_warnings = stop_on_warnings
      @never_stop = false
    end

    def warn(msg)
      if msg.class == Array
        @warnings.concat msg
      else
        @warnings << msg
      end
    end

    def continue?
      @never_stop || (!(errors? || (warnings? && @stop_on_warnings)))
    end

    def warnings?
      @warnings.size > 0
    end

    def errors?
      @errors.size > 0
    end

    def pass?
      @never_stop || errors?
    end

    def perfect_commit?
      !(errors? || warnings?)
    end

  end
end
