# frozen_string_literal: true

module DeviceChecker
  MOBILE = EveryMatrix::Category::MOBILE
  DESKTOP = EveryMatrix::Category::DESKTOP

  def platform_type(request)
    device = device(request)

    return MOBILE if device.mobile? || device.tablet?

    DESKTOP
  end

  def device(request)
    Browser.new(request.user_agent).device
  end
end
