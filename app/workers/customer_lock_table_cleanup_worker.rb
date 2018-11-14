require 'sidekiq-scheduler'

class CustomerLockTableCleanupWorker
  include Sidekiq::Worker

  def perform
    Customer
      .where.not(locked_until: nil)
      .where(
        'customers.locked_until < ?',
        Time.zone.now
      )
      .update_all(
        locked: false,
        locked_until: nil
      )
  end
end
