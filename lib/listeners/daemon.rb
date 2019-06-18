# frozen_string_literal: true

module Listeners
  class Daemon
    class << self
      def start
        Listeners::TicketAcceptanceListener.instance.listen
        Listeners::TicketCancellationListener.instance.listen

        loop { sleep(0.5) }
      end
    end
  end
end
