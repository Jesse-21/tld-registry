class Registrant::SessionsController < Devise::SessionsController
  layout 'registrant/application'
  helper_method :depp_controller?
  def depp_controller?
    false
  end

  def login
    @depp_user = Depp::User.new
  end

  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/CyclomaticComplexity
  def create
    @depp_user = Depp::User.new(params[:depp_user].merge(
      pki: !Rails.env.development?
      )
    )

    if @depp_user.pki && request.env['HTTP_SSL_CLIENT_S_DN_CN'].blank?
      @depp_user.errors.add(:base, :webserver_missing_user_name_directive)
    end

    if @depp_user.pki && request.env['HTTP_SSL_CLIENT_S_DN_CN'] == '(null)'
      @depp_user.errors.add(:base, :webserver_user_name_directive_should_be_required)
    end

    if @depp_user.pki && request.env['HTTP_SSL_CLIENT_S_DN_CN'] != params[:depp_user][:tag]
      @depp_user.errors.add(:base, :invalid_cert)
    end

    if @depp_user.errors.none? && @depp_user.valid?
      @api_user = ApiUser.find_by(username: params[:depp_user][:tag])
      if @api_user.active?
        sign_in @api_user
        redirect_to registrant_root_url
      else
        @depp_user.errors.add(:base, :not_active)
        render 'login'
      end
    else
      render 'login'
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def id
    logger.error request.env['SSL_CLIENT_S_DN']
    logger.error request.env['SSL_CLIENT_S_DN'].encoding
    @user = RegistrantUser.find_or_create_by_idc_data(request.env['SSL_CLIENT_S_DN'])
    if @user
      sign_in(@user, event: :authentication)
      redirect_to registrant_root_url
    else
      flash[:alert] = t('login_failed_check_id_card')
      redirect_to registrant_login_url
    end
  end

  def login_mid
    @user = User.new
  end

  def mid
    phone = params[:user][:phone]
    client = Digidoc::Client.new

    if Rails.env.test? && phone == "123"
      @user = ApiUser.find_by(identity_code: "14212128025")
      sign_in(@user, event: :authentication)
      return redirect_to registrant_root_url
    end

    # country_codes = {'+372' => 'EST'}
    response = client.authenticate(
      phone: "+372#{phone}",
      message_to_display: 'Authenticating',
      service_name: 'Testing'
    )

    if response.faultcode
      render json: { message: response.detail.message }, status: :unauthorized
      return
    end

    @user = find_user_by_idc(response.user_id_code)

    if @user.persisted?
      session[:user_id_code] = response.user_id_code
      session[:mid_session_code] = client.session_code
      render json: { message: t(:check_your_phone_for_confirmation_code) }, status: :ok
    else
      render json: { message: t(:no_such_user) }, status: :unauthorized
    end
  end

  # rubocop: disable Metrics/PerceivedComplexity
  # rubocop: disable Metrics/CyclomaticComplexity
  # rubocop: disable Metrics/MethodLength
  def mid_status
    client = Digidoc::Client.new
    client.session_code = session[:mid_session_code]
    auth_status = client.authentication_status

    case auth_status.status
    when 'OUTSTANDING_TRANSACTION'
      render json: { message: t(:check_your_phone_for_confirmation_code) }, status: :ok
    when 'USER_AUTHENTICATED'
      @user = find_user_by_idc(session[:user_id_code])
      sign_in @user
      flash[:notice] = t(:welcome)
      flash.keep(:notice)
      render js: "window.location = '#{registrant_root_path}'"
    when 'NOT_VALID'
      render json: { message: t(:user_signature_is_invalid) }, status: :bad_request
    when 'EXPIRED_TRANSACTION'
      render json: { message: t(:session_timeout) }, status: :bad_request
    when 'USER_CANCEL'
      render json: { message: t(:user_cancelled) }, status: :bad_request
    when 'MID_NOT_READY'
      render json: { message: t(:mid_not_ready) }, status: :bad_request
    when 'PHONE_ABSENT'
      render json: { message: t(:phone_absent) }, status: :bad_request
    when 'SENDING_ERROR'
      render json: { message: t(:sending_error) }, status: :bad_request
    when 'SIM_ERROR'
      render json: { message: t(:sim_error) }, status: :bad_request
    when 'INTERNAL_ERROR'
      render json: { message: t(:internal_error) }, status: :bad_request
    else
      render json: { message: t(:internal_error) }, status: :bad_request
    end
  end
  # rubocop: enable Metrics/PerceivedComplexity
  # rubocop: enable Metrics/CyclomaticComplexity
  # rubocop: enable Metrics/MethodLength

  def find_user_by_idc(idc)
    return User.new unless idc
    ApiUser.find_by(identity_code: idc) || User.new
  end
end