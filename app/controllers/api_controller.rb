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

  def user_datas
    role_to_datas_method = {
      'seller' => method(:user_datas_seller),
      'customer' => method(:user_datas_customer),
      'both' => method(:user_datas_both)
    }

    render_success('All your datas', role_to_datas_method[current_user&.role]&.call, :ok)
  end

  def render_success(message, data, status)
    render json: { message:, data: }, status:
  end

  def render_error(message, errors = nil, status)
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
    return render_error('Authorization token required.', :unauthorized) unless request.headers['Authorization'].present?

    jwt_payload = JWT.decode(request.headers['Authorization'].split(' ').last, ENV['DEVISE_JWT_SECRET_KEY']).first
    render json: { message: 'JWT token revoked.' }, status: :unauthorized if current_user.jwt_revoked?(jwt_payload)
  end

  def user_datas_seller
    @appointments = fetch_appointments(role: :seller)
    @appointments_serialized = @appointments.map { |appointment| serializer(appointment, AppointmentSerializer) }
    @customers = @appointments.map(&:customer).uniq(&:id)
    @customers_serialized = @customers.map { |customer| serializer(customer, UserSerializer) }
    @availabilities = current_user.availabilities.uniq(&:id)
    @availabilities_serialized = @availabilities.map { |availability| serializer(availability, AvailabilitySerializer) }
    @services = current_user.services.uniq(&:id)
    @services_serialized = @services.map { |service| serializer(service, ServiceSerializer) }

    { appointments: @appointments_serialized, customers: @customers_serialized,
      services: @services_serialized, availabilities: @availabilities_serialized }
  end

  def user_datas_customer
    @appointments = fetch_appointments(role: :customer)
    @appointments_serialized = @appointments.map { |appointment| serializer(appointment, AppointmentSerializer) }

    @sellers = @appointments.map(&:seller).uniq(&:id)
    @sellers_serialized = @sellers.map { |seller| serializer(seller, UserSerializer) }

    @services = @appointments.flat_map(&:services)
    @services_serialized = @services.map { |service| serializer(service, ServiceSerializer) }

    { appointments: @appointments_serialized, sellers: @sellers_serialized, services: @services_serialized }
  end

  def user_datas_both
    data = {}
    data[:seller] = user_datas_seller unless user_datas_seller.values.all?(&:empty?)
    data[:customer] = user_datas_customer unless user_datas_customer.values.all?(&:empty?)

    data
  end

  def fetch_appointments(role:)
    role_column = role == :seller ? :customer : :seller
    current_user.appointments.includes(role_column).where(role => current_user).uniq(&:id)
  end

  def serializer(item, serializer)
    serializer.new(item).serializable_hash[:data][:attributes]
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[firstname lastname company role phone_number])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[firstname lastname company role phone_number])
  end
end
