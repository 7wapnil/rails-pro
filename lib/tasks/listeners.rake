# frozen_string_literal: true

namespace :listeners do
  desc 'Starts all listeners for MTS'
  task start: :environment do
    path = File.join(Rails.root, 'lib', 'listeners', 'daemon_controller.rb')

    system("bundle exec ruby #{path} run")
  end

  task stop: :environment do
    path = File.join(Rails.root, 'lib', 'listeners', 'daemon_controller.rb')

    system("bundle exec ruby #{path} stop")
  end
end
