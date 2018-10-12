module Account
  class ChangePassword < ::Base::Resolver
    argument :existing_password, !types.String
    argument :new_password, !types.String
    argument :new_password_confirmation, !types.String

    type !types.Boolean

    description 'Change password'

    def resolve(_obj, args)
      params = args.to_h
      params[:subject] = @current_customer
      form = ::Forms::PasswordChange.new(params)
      form.validate!
      form.update_subject_password
    end
  end
end
