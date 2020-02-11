# frozen_string_literal: true

class GaTracker
  attr_reader :tracker_id

  def initialize(tracker_id, client_id = nil, options = {})
    @tracker_id = tracker_id
    @client_id = client_id

    @tracker = Staccato.tracker(
      @tracker_id,
      @client_id,
      options.merge(default_options)
    )
  end

  def default_options
    { ssl: true }
  end

  def track_event(params)
    Rails.logger.info(
      message: 'GA event tracking',
      payload: @tracker.build_event(params).inspect
    )
    @tracker.event(params)
  end
end
