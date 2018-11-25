module Users
  class SessionsController < Devise::SessionsController
    include Recaptcha::ClientHelper
    include Recaptcha::Verify

    layout 'minimal'

    # before_action :configure_sign_in_params, only: [:create]
    prepend_before_action :verify_captcha,  only: %i[create]
    prepend_before_action :find_login_user, only: %i[new create]


    # GET /resource/sign_in
    # def new
    #   super
    # end

    # POST /resource/sign_in
    # def create
    #   super
    # end

    # DELETE /resource/sign_out
    # def destroy
    #   super
    # end

    # protected

    # If you have extra params to permit, append them to the sanitizer.
    # def configure_sign_in_params
    #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
    # end

    private

    def find_login_user
      @login_user = resource_class.find_for_authentication(
        email: sign_in_params[:email]
      )
    end

    def verify_captcha
      return if !@login_user&.suspected_login? || verify_recaptcha

      @login_user.invalid_login_attempt!

      self.resource = resource_class.new(sign_in_params)
      flash[:alert] = flash[:recaptcha_error]

      respond_with_navigational(resource) { render :new }
    end

    def after_sign_out_path_for(_resource_or_scope)
      new_user_session_path
    end
  end
end
