# frozen_string_literal: true

class GaTracker
  def initialize(tracker_id, client_id = nil, options = {})
    @tracker_id = tracker_id
    @client_id = client_id
    @options = options
  end

  def track_event(params)
    Rails.logger.info(
      message: 'GA event tracking',
      payload: tracker.build_event(params).inspect
    )

    tracker.event(params)
  end

  private

  attr_reader :tracker_id, :client_id, :options

  def tracker
    @tracker ||= Staccato.tracker(
      tracker_id,
      client_id,
      options.merge(default_options)
    )
  end

  def default_options
    { ssl: true }
  end
end
