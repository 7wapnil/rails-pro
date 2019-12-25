# frozen_string_literal: true

module DeviceChecker
  MOBILE = EveryMatrix::PlayItem::MOBILE
  DESKTOP = EveryMatrix::PlayItem::DESKTOP

  def platform_type(request)
    device = device(request)

    return MOBILE if device.mobile? || device.tablet?

    DESKTOP
  end

  def device(request)
    Browser.new(request.user_agent).device
  end
end
