require 'sidekiq-scheduler'

class EventArchivationWorker < ApplicationWorker
  def perform
    events = Event.where.not(external_id: archived).all
    events.each do |event|
      archive(event)
    end

    Rails.logger.info "Archived #{events.count} events"
  end

  def archived
    ArchivedEvent.distinct(:external_id)
  end

  def archive(event)
    EventArchive::Service.call(event: event)
  end
end
