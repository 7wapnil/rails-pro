# frozen_string_literal: true

namespace :em_data_setup do
  desc 'EM related data setup'

  namespace :em_content_providers do
    desc 'Fill internal image name'
    UPDATE_TABLES =
      %w[every_matrix_vendors every_matrix_content_providers].freeze

    task fill_in_internal_images: :environment do
      UPDATE_TABLES.each do |table|
        execute_query(table)
      end
    end

    def execute_query(table)
      ActiveRecord::Base.connection.execute(
        "UPDATE #{table} SET internal_image_name = slug"
      )
    end
  end

  namespace :em_categories do
    desc 'Fill correct category kind an position'
    CASINO_CATEGORIES =
      %w[new favorites slots jackpots table-games skill-games].freeze
    LIVE_CASINO_CATEGORIES =
      %w[roulette blackjack poker hot-tables other-tables].freeze

    task set_kind: :environment do
      EveryMatrix::Category
        .where(context: CASINO_CATEGORIES)
        .update_all(kind: :casino)

      EveryMatrix::Category
        .where(context: LIVE_CASINO_CATEGORIES)
        .update_all(kind: :live_casino)
    end

    task set_position: :environment do
      CASINO_CATEGORIES.each_with_index do |category, index|
        EveryMatrix::Category.find_by(context: category)
                             .update(position: index + 1)
      end

      LIVE_CASINO_CATEGORIES.each_with_index do |category, index|
        EveryMatrix::Category.find_by(context: category)
                             .update(position: index + 1)
      end
    end
  end
end
