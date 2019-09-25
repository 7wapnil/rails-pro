module Events
  module BySport
    class SportEventsQuery < ::Base::Resolver
      include Base::Offsetable

      type !types[::Events::EventType]

      description 'Get all events'

      argument :filter, SportFilter
      argument :context, !types.String
      argument :titleId, !types.ID

      def auth_protected?
        false
      end

      def resolve(_obj, args)
        SportQueryResolver.new(args).resolve
      end
    end
  end
end
