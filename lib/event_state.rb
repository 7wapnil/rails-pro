class EventState < PeriodScore
  attr_reader :time,
              :period_scores,
              :finished

  def initialize(payload)
    super(payload)
    @payload = payload
    build_state!
  end

  private

  def build_state!
    return unless @payload

    @time = @payload['time']
    @finished = @payload['finished'] || false
    process_period_scores!
  end

  def process_period_scores!
    return @period_scores = [] if @payload['period_scores'].nil?

    @period_scores = @payload['period_scores'].map do |period_score|
      PeriodScore.new(period_score)
    end
  end
end
