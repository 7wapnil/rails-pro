module Forms
  class PasswordChange
    include ActiveModel::Model

    attr_accessor :existing_password, :new_password, :new_password_confirmation

    validates :existing_password,
              :new_password,
              :new_password_confirmation,
              presence: true

    validates :new_password, confirmation: true

    validates :new_password, length: { minimum: 6, maximum: 32 }
  end
end
