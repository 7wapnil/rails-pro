# frozen_string_literal: true

require 'daemons'
require File.expand_path('../../config/environment.rb', __dir__)

Daemons.run(File.join(Rails.root, 'lib', 'listeners', 'daemon.rb'),
            dir_mode: :system)
