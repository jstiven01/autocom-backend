class ApiController < ActionController::API
  include Api::ExceptionHandler

  before_action :remove_session

  def remove_session
    request.session_options[:skip] = true
  end

  def render_error_response(messages: nil, status: nil)
    status ||= :unprocessable_entity

    render json: { success: false, message: messages }, status: status
  end
end
