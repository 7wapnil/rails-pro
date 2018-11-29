module Users
  class SessionsController < Devise::SessionsController
    include Recaptcha::ClientHelper
    include Recaptcha::Verify

    helper_method :auth_session

    layout 'minimal'

    # before_action :configure_sign_in_params, only: [:create]
    # before_action :clear_session, only: :new

    before_action :clear_session, only: :new

    prepend_before_action :verify_captcha, only: :create
    prepend_before_action :login_attempt,  only: :create

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

    def clear_session
      return if auth_session.email

      session[:attempts]   = nil
      session[:last_login] = nil
    end

    def auth_session
      @auth_session = Users::SignInService.new(
        model:   resource_class,
        email:   sign_in_params[:email],
        session: session
      )
    end

    def login_attempt
      return unless auth_session.email

      session[:attempts]   = auth_session.calculate_attempts
      session[:last_login] = auth_session.email
    end

    def verify_captcha
      return if !suspected? || verify_recaptcha

      auth_session.invalid_login_attempt!

      self.resource = resource_class.new(sign_in_params)
      flash[:alert] = flash[:recaptcha_error]

      respond_with_navigational(resource) { render :new }
    end

    def suspected?
      params['g-recaptcha-response'] || auth_session.suspected?
    end

    def after_sign_out_path_for(_resource_or_scope)
      new_user_session_path
    end
  end
end
