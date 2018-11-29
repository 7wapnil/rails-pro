class EventState
  attr_reader :id,
              :status,
              :status_code,
              :score,
              :time,
              :period_scores,
              :finished

  def initialize(payload)
    @payload = payload
    build_state!
  end

  private

  def build_state!
    return [] if @payload.nil?

    @id = @payload['id'].to_i
    @status = @payload['status']
    @status_code = @payload['status_code'].to_i
    @score = @payload['score']
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
