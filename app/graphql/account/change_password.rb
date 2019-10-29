# frozen_string_literal: true

module Account
  class ChangePassword < ::Base::Resolver
    argument :existingPassword, !types.String
    argument :newPassword, !types.String
    argument :newPasswordConfirmation, !types.String

    type !types.Boolean
    mark_as_trackable

    description 'Change password'

    def resolve(_obj, args)
      params = args.to_h.deep_transform_keys!(&:underscore)
      params[:subject] = @current_customer
      form = ::Forms::PasswordChange.new(params)
      form.validate!
      form.update_subject_password
    end
  end
end
