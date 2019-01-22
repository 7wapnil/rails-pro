module App
  class AppQuery < ::Base::Resolver
    type !AppType

    description 'Get the actual application info'

    def auth_protected?
      false
    end

    def resolve(_obj, _args)
      ::ApplicationState.instance.state
    end
  end
end
