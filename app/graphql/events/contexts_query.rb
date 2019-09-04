module Events
  class ContextsQuery < ::Base::Resolver
    type !types[ContextType]

    description 'Get event contexts to show'

    argument :filter, EventFilter
    argument :contexts, types[Events::ContextEnum]

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      ContextsQueryResolver.new(args).resolve
    end
  end
end
