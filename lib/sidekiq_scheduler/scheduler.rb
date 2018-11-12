# Monkey-patch to original Scheduler https://bit.ly/2PKAlgy
# Line 144 removed, everything else is the same

module SidekiqScheduler
  class Scheduler
    def idempotent_job_enqueue(job_name, time, config)
      registered =
        SidekiqScheduler::RedisManager.register_job_instance(job_name, time)

      if registered
        handle_errors { enqueue_job(config, time) }

        SidekiqScheduler::RedisManager.remove_elder_job_instances(job_name)
      else
        Sidekiq
          .logger
          .debug { "Ignoring #{job_name} job as it has been already enqueued" }
      end
    end
  end
end
