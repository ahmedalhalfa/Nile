require "swagger_helper"

describe "Authentication API" do
  path "/api/v1/auth/register" do
    post "Registers a new user" do
      tags "Authentication"
      consumes "application/json"
      produces "application/json"
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string },
          username: { type: :string },
          password: { type: :string },
        },
        required: ["email", "username", "password"],
      }

      response "201", "user created" do
        schema type: :object,
               properties: {
                 token: { type: :string },
                 user: {
                   type: :object,
                   properties: {
                     id: { type: :integer },
                     email: { type: :string },
                     username: { type: :string },
                   },
                   required: ["id", "email", "username"],
                 },
               },
               required: ["token", "user"]
        let(:user) { { email: "test@example.com", username: "testuser", password: "password123" } }
        run_test!
      end

      response "422", "invalid request" do
        schema "$ref" => "#/components/schemas/errors_object"
        let(:user) { { email: "invalid-email", username: "tu", password: "pw" } }
        run_test!
      end
    end
  end

  path "/api/v1/auth/login" do
    post "Logs in a user" do
      tags "Authentication"
      consumes "application/json"
      produces "application/json"
      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string },
          password: { type: :string },
        },
        required: ["email", "password"],
      }

      response "200", "user logged in" do
        schema type: :object,
               properties: {
                 token: { type: :string },
                 user: {
                   type: :object,
                   properties: {
                     id: { type: :integer },
                     email: { type: :string },
                     username: { type: :string },
                   },
                   required: ["id", "email", "username"],
                 },
               },
               required: ["token", "user"]
        let(:existing_user) { create(:user, password: "password123") } # Assumes FactoryBot
        let(:credentials) { { email: existing_user.email, password: "password123" } }
        run_test!
      end

      response "401", "unauthorized" do
        let(:existing_user) { create(:user, password: "password123") }
        let(:credentials) { { email: existing_user.email, password: "wrongpassword" } }
        run_test!
      end
    end
  end

  path "/api/v1/auth/forgot_password" do
    post "Requests a password reset" do
      tags "Authentication"
      consumes "application/json"
      produces "application/json"
      parameter name: :email_param, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string },
        },
        required: ["email"],
      }, description: "Specify the user email to send reset instructions to"

      response "200", "reset instructions sent" do
        schema type: :object, properties: { message: { type: :string } }
        let(:existing_user) { create(:user) }
        let(:email_param) { { email: existing_user.email } }
        run_test!
      end

      response "404", "email not found" do
        schema type: :object, properties: { error: { type: :string } }
        let(:email_param) { { email: "nonexistent@example.com" } }
        run_test!
      end
    end
  end

  path "/api/v1/auth/reset_password" do
    post "Resets the password using a token" do
      tags "Authentication"
      consumes "application/json"
      produces "application/json"
      parameter name: :reset_params, in: :body, schema: {
        type: :object,
        properties: {
          token: { type: :string },
          password: { type: :string },
        },
        required: ["token", "password"],
      }

      response "200", "password reset successful" do
        schema type: :object, properties: { message: { type: :string } }
        let(:user_with_token) { create(:user) }
        before { user_with_token.generate_password_reset_token }
        let(:reset_params) { { token: user_with_token.reset_password_token, password: "newpassword123" } }
        run_test!
      end

      response "422", "invalid or expired token / invalid password" do
        schema type: :object, properties: { error: { type: :string } }
        let(:reset_params) { { token: "invalidtoken", password: "newpassword123" } }
        run_test!
      end
    end
  end

  path "/api/v1/auth/change_password" do
    put "Changes the password for the authenticated user" do
      tags "Authentication"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :password_change, in: :body, schema: {
        type: :object,
        properties: {
          current_password: { type: :string },
          new_password: { type: :string },
        },
        required: ["current_password", "new_password"],
      }

      response "200", "password changed successfully" do
        schema type: :object, properties: { message: { type: :string } }
        let(:current_user_instance) { create(:user, password: "oldpassword123") }
        let(:Authorization) { "Bearer #{JwtService.encode(user_id: current_user_instance.id)}" }
        let(:password_change) { { current_password: "oldpassword123", new_password: "newpassword456" } }
        run_test!
      end

      response "401", "unauthorized or incorrect current password" do
        schema type: :object, properties: { error: { type: :string } }
        let(:current_user_instance) { create(:user, password: "oldpassword123") }
        let(:Authorization) { "Bearer #{JwtService.encode(user_id: current_user_instance.id)}" }
        let(:password_change) { { current_password: "wrongpassword", new_password: "newpassword456" } }
        run_test!
      end

      response "422", "invalid new password" do
        schema "$ref" => "#/components/schemas/errors_object"
        let(:current_user_instance) { create(:user, password: "oldpassword123") }
        let(:Authorization) { "Bearer #{JwtService.encode(user_id: current_user_instance.id)}" }
        let(:password_change) { { current_password: "oldpassword123", new_password: "short" } }
        run_test!
      end
    end
  end
end
