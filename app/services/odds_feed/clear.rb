# frozen_string_literal: true

module OddsFeed
  class Clear < ApplicationService
    def call
      clear_players
      clear_competitors
      clear_bets
      clear_odds
      clear_markets
      clear_events
    end

    private

    def clear_players
      puts 'Destroying players ...'
      CompetitorPlayer.delete_all
      Player.delete_all
      puts 'Done!'
    end

    def clear_competitors
      puts 'Destroying competitors ...'
      EventCompetitor.delete_all
      Competitor.delete_all
      puts 'Done!'
    end

    def clear_bets
      puts 'Removing origin-bet from entry requests ...'
      EntryRequest
        .where(origin_type: Bet.name)
        .update_all(origin_type: nil, origin_id: nil)
      puts 'Done!'

      puts 'Removing origin-bet from entries ...'
      Entry
        .where(origin_type: Bet.name)
        .update_all(origin_type: nil, origin_id: nil)
      puts 'Done!'

      puts 'Destroying bets ...'
      Bet.delete_all
      puts 'Done!'
    end

    def clear_odds
      puts 'Destroying odds ...'
      Odd.delete_all
      puts 'Done!'
    end

    def clear_markets
      puts 'Removing market labels ...'
      LabelJoin.where(labelable_type: Market.name).delete_all
      puts 'Done!'

      puts 'Destroying markets ...'
      Market.delete_all
      puts 'Done!'
    end

    def clear_events
      puts 'Destroying events ...'
      ScopedEvent.delete_all
      Event.delete_all
      EventScope.delete_all
      puts 'Done!'
    end
  end
end
