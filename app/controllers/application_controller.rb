class ApplicationController < ActionController::API
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found_response

    private

    def render_not_found_response(exception)
        render json: { error: "#{exception.model} not found" }, status: :unprocessable_entity
    end
end
