# Controller for API USE RENDER JSON ##
class ApiController < ActionController::API
  before_action :configure_permitted_parameters, if: :devise_controller?
  rescue_from ActionController::UnpermittedParameters, with: :handle_errors

  def user_search
    @query = params[:query].downcase
    @role = params[:role].downcase
    verify_search(@query, @role)
    @users = find_user(@query, @role)
    render_success("#{@role.capitalize}(s) founded.", @users, :ok) if @users.length.positive?
    render_error("#{@role.capitalize}(s) not found.", :not_found) if @users.empty?
  end

  def render_success(message, data, status)
    render json: { message: message, data: data }, status: status
  end

  def render_error(message, status)
    render json: { errors: message }, status: status
  end

  private

  def verify_search(query, role)
    return render_error('Query required !', :unprocessable_entity) unless query
    return render_error('Role required !', :unprocessable_entity) unless role
    return render_error('Role not include in the users roles !', :unprocessable_entity) unless User.roles.keys.include?(role)
  end

  def handle_errors
    render json: { "Unpermitted Parameters": params.to_unsafe_h.except(:controller, :action, :id).keys }, status: :unprocessable_entity
  end

  def find_user(query, role)
    User.search_by_firstname_and_lastname(query).where(role: role)
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[firstname lastname entreprise])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[firstname lastname entreprise])
  end
end
