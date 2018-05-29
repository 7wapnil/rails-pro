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

  def self.discipline
    @discipline ||= Discipline.find_or_create_by!(name: 'CS:GO') do |discipline|
      discipline.kind = :esports
    end
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def self.create_event(attributes)
    tournament = EventScope.tournament.order(Arel.sql('RANDOM()')).first
    teams = CSGO_TEAMS.sample(2)
    event_name = "#{teams.first} vs #{teams.last}"

    default_attributes = {
      discipline: discipline,
      name: event_name,
      description: "#{tournament.name}: #{event_name}",
      start_at: Time.zone.now.beginning_of_hour
    }

    event = Event.new(default_attributes.merge(attributes))
    event.event_scopes << tournament
    event.save!

    market = event.markets.create!(name: 'Match Winner', priority: 1)

    teams.each do |name|
      odd = market.odds.create!(name: name)
      odd.odd_values.create!(value: Faker::Number.between(1.1, 9.9).round(2))
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
end

puts 'Checking Discipline ...'

discipline = CsgoPrimer.discipline

puts 'Checking Tournaments ...'

CsgoPrimer::CSGO_TOURNAMENTS.each do |name|
  EventScope.find_or_create_by!(name: name) do |tournament|
    tournament.discipline = discipline
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