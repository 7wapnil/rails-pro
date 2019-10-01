# frozen_string_literal: true

namespace :database do
  desc 'Depersonalize production database'
  task depersonalize: :environment do
    Database::Depersonalize.call
  end
end
