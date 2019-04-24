module EventsManager
  module Logger
    def log(level, message)
      Rails.logger.send(level, "[EventsManager] #{message}")
    end
  end
end
