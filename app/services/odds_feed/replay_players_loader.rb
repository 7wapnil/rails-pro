# frozen_string_literal: true

module OddsFeed
  class ReplayPlayersLoader < ApplicationService
    BATCH_SIZE = 2000

    def call
      spreadsheet.each_slice(BATCH_SIZE).with_index(&method(:load_players))
    end

    private

    def spreadsheet
      CSV.parse(raw_data, headers: true)
    end

    def raw_data
      File.read(Rails.root.join('certification', 'missing_players.csv'))
    end

    def load_players(batch, batch_index)
      players = batch.map { |player_data| Player.new(player_data.to_h) }

      Player.import(players, on_duplicate_key_ignore: true)
      puts "== #{batch_index * BATCH_SIZE + batch.length} players loaded =="
    end
  end
end
