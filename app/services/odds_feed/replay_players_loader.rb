# frozen_string_literal: true

module OddsFeed
  class ReplayPlayersLoader < ApplicationService
    BATCH_SIZE = 2000

    def call
      data.each_slice(BATCH_SIZE).with_index(&method(:load_players))
    end

    private

    def data
      JSON.parse(
        File.read(players_data_path)
      )
    end

    def players_data_path
      Rails.root.join('certification', 'missing_players.json')
    end

    def load_players(batch, batch_index)
      players = batch.map { |player_data| Player.new(player_data) }

      Player.import(players, on_duplicate_key_ignore: true)
      puts "== #{batch_index * BATCH_SIZE + batch.length} players loaded =="
    end
  end
end
