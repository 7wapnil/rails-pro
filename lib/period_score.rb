class PeriodScore
  attr_reader :id,
              :status,
              :status_code,
              :score

  def initialize(payload)
    @payload = payload
    @payload = payload
    build_score!
  end

  private

  def build_score!
    return unless @payload

    @id = @payload['id'].to_i
    @status = @payload['status']
    @status_code = @payload['status_code'].to_i
    @score = @payload['score']
  end
end
