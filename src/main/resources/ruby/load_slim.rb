# This file is loaded once for every view that is instantiated.
# It uses (requires) a separate file to avoid loading the same code multiple times.
require 'ruby/slim_helper'
require 'source_reloader' if SystemUtils.development?
