module Forms
  class PasswordChange
    include ActiveModel::Model

    attr_accessor :subject, :existing_password, :new_password, :new_password_confirmation

    validates :subject,
              :existing_password,
              :new_password,
              :new_password_confirmation,
              presence: true

    validates :new_password, confirmation: true

    validates :new_password, length: { minimum: 6, maximum: 32 }

    def update_subject_password
      raise FormInvalidError unless valid?

      subject.update_with_password(
        current_password: existing_password,
        password: new_password,
        password_confirmation: new_password_confirmation
      )
    end
  end
end
