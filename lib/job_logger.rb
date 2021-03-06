module JobLogger
  def log_job_failure(error)
    message = error.is_a?(Exception) ? error.message : error

    log_job_message(:error, message: message, error_object: error)
  end

  protected

  def log_job_message(level, payload)
    return Rails.logger.send(level, payload) unless job_id

    data = payload.is_a?(Hash) ? payload : { message: payload }

    Rails.logger.send(
      level,
      jid: job_id,
      class_name: self.class.name,
      current_time: current_time,
      thread_id: thread_id,
      **data,
      **extra_log_info
    )
  end

  def log_success
    msg = "#{self.class.name} successfully finished a job"
    log_process(:info, msg)
  end

  def log_failure(error)
    log_process(:error, error.message, error_object: error)
  end

  private

  def log_process(level, message = nil, **args)
    Rails.logger.send(level,
                      jid: job_id,
                      worker: self.class.name,
                      message: message,
                      current_time: current_time,
                      job_enqueued_at: enqueued_at,
                      job_performing_time: performing_time.round(3),
                      job_execution_time: execution_time.round(3),
                      overall_processing_time: processing_time.round(3),
                      thread_id: thread_id,
                      **args,
                      **odd_messages_info,
                      **extra_log_info)
  end

  def odd_messages_info
    {
      event_id: event_id,
      message_producer_id: message_producer_id,
      message_timestamp: message_timestamp,
      event_producer_id: event_producer_id
    }
  end

  def event_id
    Thread.current[:event_id]
  end

  def message_producer_id
    Thread.current[:message_producer_id]
  end

  def message_timestamp
    Thread.current[:message_timestamp]
  end

  def event_producer_id
    Thread.current[:event_producer_id]
  end

  def enqueued_at
    Thread.current[:enqueued_at]
  end

  def start_time
    Thread.current.fetch(:start_time)
  rescue KeyError
    log_thread_info_missing(:start_time)
    Time.now.to_f
  end

  def log_thread_info_missing(option)
    Rails.logger.warn(
      jid: job_id,
      worker: self.class.name,
      message: "`#{option}` is missing in thread"
    )
  end

  def job_id
    Thread.current[:job_id]
  end

  def thread_id
    Thread.current.object_id
  end

  def current_time
    @current_time ||= Time.zone.now.to_datetime
  end

  def performing_time
    enqueued_at.to_i.zero? ? 0 : current_time.to_f - enqueued_at.to_f
  end

  def execution_time
    current_time.to_f - start_time
  end

  def processing_time
    performing_time + execution_time
  end

  def extra_log_info
    {}
  end
end
