class EventState < PeriodScore
  attr_reader :time,
              :period_scores,
              :finished

  def initialize(payload)
    super(payload)
    build_state! payload
  end

  private

  def build_state!(payload)
    return unless payload

    @time = payload['time']
    @finished = payload['finished'] || false
    process_period_scores! payload
  end

  def process_period_scores!(payload)
    return @period_scores = [] if payload['period_scores'].nil?

    @period_scores = payload['period_scores'].map do |period_score|
      PeriodScore.new(period_score)
    end
  end
end
