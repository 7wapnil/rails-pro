module EventsManager
  module Logger
    def log(level, payload)
      data = payload.is_a?(Hash) ? payload : { message: payload }

      Rails.logger.send(level,
                        category: 'EventsManager',
                        **data)
    end
  end
end
