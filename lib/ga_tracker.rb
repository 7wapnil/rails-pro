class GaTracker
  attr_reader :tracker_id

  def initialize(tracker_id = ENV['GA_TRACKER_ID'], client_id = nil)
    @tracker_id = tracker_id
    @client_id = client_id
    @tracker = Staccato.tracker(@tracker_id, @client_id, ssl: true)
  end

  def track_event(params)
    @tracker.event(params)
  end
end
