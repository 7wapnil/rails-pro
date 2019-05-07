require 'sidekiq-scheduler'

class EventArchivationWorker < ApplicationWorker
  def perform
    events = Event.where.not(external_id: archived).all
    events.each { |event| archive(event) }

    log_job_message(:info, message: 'Events archivation',
                           events_count: events.count)
  end

  def archived
    ArchivedEvent.distinct(:external_id)
  end

  def archive(event)
    EventArchive::Service.call(event: event)
  end
end
