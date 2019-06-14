# frozen_string_literal: true

module Listeners
  class Daemon
    class << self
      def start
        Listeners::TicketAcceptanceListener.instance.listen
        Listeners::TicketCancellationListener.instance.listen
      end
    end
  end
end

::Listeners::Daemon.start

loop { ; }
