# frozen_string_literal: true

return unless Rails.env.development?

Bullet.enable = true
Bullet.rails_logger = true
