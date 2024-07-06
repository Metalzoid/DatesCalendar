class ConfirmationsController < Devise::ConfirmationsController
  respond_to :json

  private

  def render_resource(resource)
    render json: resource
  end

  def render_resource_or_errors(resource, status)
    if resource.errors.empty?
      render json: resource, status: status
    else
      render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
