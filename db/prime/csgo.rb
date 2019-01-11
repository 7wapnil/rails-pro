require 'faker'

class CsgoPrimer # rubocop:disable Metrics/ClassLength
  CSGO_TEAMS = %w[
    SK
    Natus
    Fnatic
    Astralis
    Gamers2
    NiP
    EnVyUs
    Virtus
    Liquid
    Immortals
    Dignitas
    Team
    OpTic
    TSM
    Mousesports
    Cloud9
    TyLoo
    HellRaisers
    CLG
    FlipSid3
    FaZe
    MK
    Gambit
  ].freeze

  CSGO_TOURNAMENTS = [
    'Esl Anz Championship',
    'King of Nordic',
    'Esl Meisterschaft',
    'Esl Proximus Championship',
    'Esl Championnat National',
    'Farms Championship',
    'Esl UK Premiership',
    'Esl Southeast Europe Championship',
    'Esl Masters España',
    'ESL Pro League'
  ].freeze

  REASONABLE_MATCH_TIME = 3.hours.freeze

  class << self
    def title
      @title ||= Title.find_or_create_by!(name: 'CS:GO') do |title|
        title.kind = Title::ESPORTS
      end
    end

    def create_event(attributes)
      default_attributes, market_external_id, odd_external_id,
        teams, tournament = prepare_event_related_data

      event = Event.new(default_attributes.merge(attributes))
      event.event_scopes << tournament
      event.add_to_payload(
        state:
          OddsFeed::Radar::EventStatusService.new.call(
            event_id: Faker::Number.number(3), data: nil
          )
      )
      event.save!

      market = create_market(event, market_external_id)
      create_odds(market, odd_external_id, teams)
    end

    private

    def prepare_event_related_data # rubocop:disable Metrics/MethodLength:
      tournament = EventScope.tournament.order(Arel.sql('RANDOM()')).first
      teams = CSGO_TEAMS.sample(2)
      event_name = "#{teams.first} vs #{teams.last}"
      match_id = Faker::Number.number(8)
      event_external_id = ['sr', 'match', match_id].join(':')
      market_external_id =
        [event_external_id, Faker::Number.number(2)].join(':')
      odd_external_id =
        [market_external_id, Faker::Number.number(2)].join(':')

      default_attributes = {
        title: title,
        name: event_name,
        description: "#{tournament.name}: #{event_name}",
        start_at: Time.zone.now.beginning_of_hour,
        traded_live: [true, false].sample,
        payload: {},
        external_id: event_external_id
      }
      [default_attributes, market_external_id,
       odd_external_id, teams, tournament]
    end

    def create_odds(market, odd_external_id, teams)
      teams.each_with_index do |name, index|
        market.odds.create!(
          name: name,
          status: Odd::ACTIVE,
          value: Faker::Number.between(1.1, 9.9).round(2),
          external_id: [
            odd_external_id,
            index
          ].join('')
        )
      end
    end

    def create_market(event, market_external_id)
      event.markets.create!(
        name: 'Match Winner',
        priority: 1,
        status: Market::ACTIVE,
        external_id: market_external_id
      )
    end
  end
end

puts 'Checking Title ...'

title = CsgoPrimer.title

puts 'Checking Tournaments ...'

CsgoPrimer::CSGO_TOURNAMENTS.each_with_index do |name, index|
  EventScope.find_or_create_by!(name: name) do |tournament|
    tournament.title = title
    tournament.kind = EventScope::TOURNAMENT
    tournament.external_id =
      ['sr:tournament', index].join(':')
  end
end

puts 'Finishing past in-play Matches ...'

Event.unscoped.where(
  'start_at < ? AND end_at IS NULL',
  CsgoPrimer::REASONABLE_MATCH_TIME.ago
).find_each(batch_size: 100) do |event|
  event.update_attributes!(end_at: event.start_at + 2.hours)
end

puts 'Checking current in-play Matches ...'

if Event.where(
  'start_at > ? AND end_at = ?',
  CsgoPrimer::REASONABLE_MATCH_TIME.ago,
  nil
).count < 3
  3.times do
    start_at =
      Faker::Time.between(2.hours.ago, Time.zone.now).beginning_of_hour

    CsgoPrimer.create_event(start_at: start_at)
  end
end

puts 'Creating more future Matches ...'

if Event.where('end_at IS NULL').count < 20
  10.times do
    start_at =
      Faker::Time.between(Time.zone.now, 1.day.from_now).beginning_of_hour

    CsgoPrimer.create_event(start_at: start_at)
  end
end
