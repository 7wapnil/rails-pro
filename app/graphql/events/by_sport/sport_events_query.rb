module Events
  module BySport
    class SportEventsQuery < ::Base::Resolver
      include Base::Offsetable

      type !types[::Events::EventType]
      cache_for :cache_expiration

      description 'Get all events'

      argument :context, !types.String
      argument :titleId, !types.ID

      def auth_protected?
        false
      end

      def cache_expiration(args)
        case args.context
        when Event::LIVE
          EVENT_LIVE_CONTEXT_CACHE_TTL
        when Event::UPCOMING
          EVENT_UPCOMING_CONTEXT_CACHE_TTL
        end
      end

      def resolve(_obj, args)
        SportQueryResolver.new(args).resolve
      end
    end
  end
end
