module App
  class AppQuery < ::Base::Resolver
    type !AppType

    description 'Get the actual application info'

    def auth_protected?
      false
    end

    def resolve(_obj, _args)
      app_state = ::ApplicationState
      OpenStruct.new(status: app_state.instance.status,
                     statuses: app_state::STATUSES.keys,
                     flags: app_state.instance.flags)
    end
  end
end
