module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_request, only: [:register, :login, :forgot_password, :reset_password]

      # POST /api/v1/auth/register
      def register
        user = User.new(user_params)

        if user.save
          token = JwtService.encode(user_id: user.id)
          render json: { token: token, user: user_response(user) }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/auth/login
      def login
        user = User.find_by(email: params[:email])

        if user&.authenticate(params[:password])
          token = JwtService.encode(user_id: user.id)
          render json: { token: token, user: user_response(user) }
        else
          render json: { error: "Invalid email or password" }, status: :unauthorized
        end
      end

      # POST /api/v1/auth/forgot_password
      def forgot_password
        user = User.find_by(email: params[:email])

        if user
          user.generate_password_reset_token
          # In a real app, send an email with the token
          # UserMailer.reset_password(user, reset_link).deliver_later

          render json: { message: "Password reset instructions sent to your email" }
        else
          render json: { error: "Email not found" }, status: :not_found
        end
      end

      # POST /api/v1/auth/reset_password
      def reset_password
        user = User.find_by(reset_password_token: params[:token])

        if user && user.password_reset_token_valid?
          if params[:password].present? && params[:password].length >= 6
            if user.reset_password(params[:password])
              render json: { message: "Password has been reset successfully" }
            else
              render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
            end
          else
            render json: { error: "Password is too short (minimum is 6 characters)" }, status: :unprocessable_entity
          end
        else
          render json: { error: "Invalid or expired token" }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/auth/change_password
      def change_password
        if current_user.authenticate(params[:current_password])
          if current_user.update(password: params[:new_password])
            render json: { message: "Password changed successfully" }
          else
            render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
          end
        else
          render json: { error: "Current password is incorrect" }, status: :unauthorized
        end
      end

      private

      def user_params
        params.permit(:email, :username, :password)
      end

      def user_response(user)
        {
          id: user.id,
          email: user.email,
          username: user.username,
        }
      end
    end
  end
end
