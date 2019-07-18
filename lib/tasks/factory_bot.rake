namespace :factory_bot do
  desc 'Verify that all FactoryBot factories are valid'
  task lint: :environment do
    require 'faker'
    require 'factory_bot_rails'

    if Rails.env.test?
      DatabaseCleaner.clean_with(:deletion)
      DatabaseCleaner.cleaning do
        FactoryBot.lint(traits: true)
      end
    else
      system("bundle exec rake factory_bot:lint RAILS_ENV='test'")
      raise if $CHILD_STATUS.exitstatus.nonzero?
    end
  end
end
