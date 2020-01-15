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

    task set_positions: :environment do
      PRIORITY_LIST = {
        'net-ent' => 1,
        'big-time-gaming' => 2,
        'blueprint' => 3,
        'egt' => 4,
        'quick-spin' => 5,
        'pragmatic-play' => 6,
        'gamomat' => 7,
        'elk-gaming' => 8,
        'evolution-gaming' => 9,
        'red-tiger-gaming' => 10,
        'relax-gaming' => 11,
        'bee-fee' => 12,
        'microgaming' => 13,
        'pariplay' => 14,
        'skillzz-gaming' => 15,
        'spigo' => 16,
        'oryx-gaming' => 17,
        'playson' => 18,
        'bet-soft' => 19,
        'gamevy' => 20,
        'bet-games' => 21
      }.freeze

      PRIORITY_LIST.each do |provider, index|
        [EveryMatrix::Vendor, EveryMatrix::ContentProvider].each do |table|
          result = table.find_by(slug: provider)&.update(position: index)

          break if result
        end
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
