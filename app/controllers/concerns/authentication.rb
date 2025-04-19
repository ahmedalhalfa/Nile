module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request
    rescue_from JWT::DecodeError, with: :unauthorized

    attr_reader :current_user
  end

  private

  def authenticate_request
    @current_user = find_user_from_token
    unauthorized unless @current_user
  end

  def find_user_from_token
    token = extract_token_from_header
    return nil unless token

    payload = JwtService.decode(token)
    return nil unless payload

    User.find_by(id: payload[:user_id])
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def extract_token_from_header
    header = request.headers["Authorization"]
    header&.split(" ")&.last
  end

  def unauthorized
    render json: { error: "Unauthorized" }, status: :unauthorized
  end
end
