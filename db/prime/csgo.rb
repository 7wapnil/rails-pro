require 'faker'

class CsgoPrimer
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
    'X-BET.CO INVITATIONAL',
    'SL COLOGNE 2018 QUALIFIER',
    'SEA MAIN SEASON 27',
    'EGEND SERIES 5',
    'EM SYDNEY',
    'TARSERIES QUALIFIER',
    'USION.BET MASTERS',
    'AMDOM PREMIER',
    'ETSPAWN CUP',
    'OCASE CHALLENGE'
  ].freeze

  REASONABLE_MATCH_TIME = 3.hours.freeze

  def self.title
    @title ||= Title.find_or_create_by!(name: 'CS:GO') do |title|
      title.kind = :esports
    end
  end

  class << self
    def create_event(attributes)
      default_attributes, market_external_id, odd_external_id,
        teams, tournament = prepare_event_related_data

      event = Event.new(default_attributes.merge(attributes))
      event.event_scopes << tournament
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
      live_event_producer_payload =
        { "producer": { "origin": 'radar', "id": '1' } }

      default_attributes = {
        title: title,
        name: event_name,
        description: "#{tournament.name}: #{event_name}",
        start_at: Time.zone.now.beginning_of_hour,
        payload: live_event_producer_payload,
        external_id: event_external_id
      }
      [default_attributes, market_external_id,
       odd_external_id, teams, tournament]
    end

    def create_odds(market, odd_external_id, teams)
      teams.each do |name|
        market.odds.create!(
          name: name,
          status: :active,
          value: Faker::Number.between(1.1, 9.9).round(2),
          external_id: odd_external_id
        )
      end
    end

    def create_market(event, market_external_id)
      event.markets.create!(
        name: 'Match Winner',
        priority: 1,
        status: :active,
        external_id: market_external_id
      )
    end
  end
end

puts 'Checking Title ...'

title = CsgoPrimer.title

puts 'Checking Tournaments ...'

CsgoPrimer::CSGO_TOURNAMENTS.each do |name|
  EventScope.find_or_create_by!(name: name) do |tournament|
    tournament.title = title
    tournament.kind = :tournament
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
