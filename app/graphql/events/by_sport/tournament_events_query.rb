module Events
  module BySport
    class TournamentEventsQuery < ::Base::Resolver
      include Base::Offsetable

      type TournamentEventsType

      description 'Get all events'

      argument :id, !types.ID

      def auth_protected?
        false
      end

      def resolve(_obj, args)
        TournamentQueryResolver.new(args).resolve
      end
    end
  end
end
