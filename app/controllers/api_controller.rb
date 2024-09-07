# frozen_string_literal: true

# Controller for API USE RENDER JSON ##
class ApiController < ActionController::API
  before_action :authenticate_user!
  before_action :custom_authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  rescue_from ActionController::UnpermittedParameters, with: :handle_errors

  # URL = url/user_search?query=NAME&role=ROLE
  # @summary Search a User
  # - Required: query. Query is a part of the firstname or lastname of a user.
  # - Optional: role.
  # @parameter query(query) [String] The part of firstname or lastname of the user.
  # @response Role not include in the users roles !.(422) [Hash{message: String}]
  # @response Users founded.(200) [Hash{message: String, data: Hash}]
  # @response Users not found.(404) [Hash{message: String}]
  # @tags Users
  # @auth [bearer_jwt]
  def user_search
    @query = params[:query].downcase if params[:query].present?
    @role = params[:role].downcase if params[:role].present?
    @user_id = params[:user_id].to_i if params[:user_id].present?
    @user = User.by_admin(current_user.admin).find_by(id: @user_id)
    return render_success('User founded by id.', UserSerializer.new(@user).serializable_hash[:data][:attributes], :ok) if @user_id && @user

    return if verify_search(@query, @role)

    @users = find_user(@query, @role)
    return render_success("#{@role ? @role.capitalize : 'User'}(s) founded.", @users, :ok) if @users.length.positive?

    render_error("#{@role ? @role.capitalize : 'User'}(s) not found.", :not_found) if @users.empty?
  end

  def render_success(message, data, status)
    render json: { message:, data: }, status:
  end

  def render_error(message, errors = nil, status )
    render json: { message:, errors: }, status:
  end

  private

  def verify_search(query, role)
    return render_error('Query required !', :unprocessable_entity) if query.nil? || query.empty?
    return if role.nil? || role.empty?

    render_error('Role not include in the users roles !', :unprocessable_entity) unless User.roles.keys.include?(role)
  end

  def handle_errors
    render json: { "Unpermitted Parameters": params.to_unsafe_h.except(:controller, :action, :id).keys },
           status: :unprocessable_entity
  end

  def find_user(query, _role)
    User.by_admin(current_user.admin).search_by_firstname_and_lastname(query)
  end

  def custom_authenticate_user!
    if request.headers['Authorization'].present?
      jwt_payload = JWT.decode(request.headers['Authorization'].split(' ').last, ENV['DEVISE_JWT_SECRET_KEY']).first
    else
      return render_error('Authorization token required.', :unauthorized)
    end
    render json: { message: 'JWT token revoked.' }, status: :unauthorized if current_user.jwt_revoked?(jwt_payload)
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[firstname lastname company role])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[firstname lastname company role])
  end
end
