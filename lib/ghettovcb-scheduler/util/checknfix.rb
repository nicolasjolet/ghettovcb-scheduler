require 'ghettovcb-scheduler/util/config'

module Checknfix
  class << self
    def check

    end
  end
end

# Only run the following code when this file is the main file being run
# instead of having been required or loaded by another file
if __FILE__ == $PROGRAM_NAME
  Checknfix.check
end