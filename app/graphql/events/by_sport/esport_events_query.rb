module Events
  module BySport
    class EsportEventsQuery < ::Base::Resolver
      include Base::Offsetable

      type !types[::Events::EventType]

      description 'Get all events'

      argument :filter, EsportFilter
      argument :context, types.String

      def auth_protected?
        false
      end

      def resolve(_obj, args)
        EsportQueryResolver.new(args).resolve
      end
    end
  end
end
