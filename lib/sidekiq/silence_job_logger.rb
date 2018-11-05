module Sidekiq
  class SilenceJobLogger
    def call(*)
      yield
    end
  end
end
