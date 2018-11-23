module App
  class AppQuery < ::Base::Resolver
    type !AppType

    description 'Get the actual application info'

    def auth_protected?
      false
    end

    def resolve(_obj, _args)
      app_state = ::ApplicationState.instance
      OpenStruct.new(status: app_state.status,
                     statuses: ::ApplicationState::STATUSES.keys,
                     live_connected: app_state.live_connected,
                     pre_live_connected: app_state.pre_live_connected)
    end
  end
end
