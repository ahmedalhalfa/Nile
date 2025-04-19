require "swagger_helper"
require "rails_helper"

describe "Authentication API" do
  path "/api/v1/auth/register" do
    post "Registers a new user" do
      tags "Authentication"
      consumes "application/json"
      produces "application/json"
      parameter name: :user_params, in: :body, schema: {
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

        context "with valid parameters" do
          let(:user_params) { { email: "test@example.com", username: "testuser", password: "password123" } }

          it "creates a new user" do
            expect {
              post "/api/v1/auth/register", params: user_params.to_json, headers: { "Content-Type" => "application/json" }
            }.to change(User, :count).by(1)
          end

          it "returns the user and a token" do
            post "/api/v1/auth/register", params: user_params.to_json, headers: { "Content-Type" => "application/json" }
            expect(response).to have_http_status(:created)
            expect(response_body[:user][:email]).to eq("test@example.com")
            expect(response_body[:user][:username]).to eq("testuser")
            expect(response_body[:token]).to be_present

            decoded_token = JwtService.decode(response_body[:token])
            expect(decoded_token[:user_id]).to eq(User.find_by(email: "test@example.com").id)
          end

          run_test!
        end
      end

      response "422", "invalid request" do
        schema "$ref" => "#/components/schemas/errors_object"
        context "with invalid parameters" do
          let(:user_params) { { email: "invalid-email", username: "tu", password: "pw" } }

          before { post "/api/v1/auth/register", params: user_params.to_json, headers: { "Content-Type" => "application/json" } }

          it "does not create a user" do
            expect(User.count).to eq(0)
          end

          it "returns validation errors" do
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response_body[:errors]).to include("Email is invalid", "Username is too short (minimum is 5 characters)", "Password is too short (minimum is 6 characters)")
          end

          run_test!
        end
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

      let!(:existing_user) { create(:user, email: "login@example.com", password: "password123") }

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

        context "with valid credentials" do
          let(:credentials) { { email: existing_user.email, password: "password123" } }

          before { post "/api/v1/auth/login", params: credentials.to_json, headers: { "Content-Type" => "application/json" } }

          it "returns the user and a token" do
            expect(response).to have_http_status(:ok)
            expect(response_body[:user][:id]).to eq(existing_user.id)
            expect(response_body[:token]).to be_present
          end

          run_test!
        end
      end

      response "401", "unauthorized" do
        context "with invalid credentials" do
          let(:credentials) { { email: existing_user.email, password: "wrongpassword" } }

          before { post "/api/v1/auth/login", params: credentials.to_json, headers: { "Content-Type" => "application/json" } }

          it "returns unauthorized status" do
            expect(response).to have_http_status(:unauthorized)
          end

          it "returns an error message" do
            expect(response_body[:error]).to eq("Invalid email or password")
          end

          run_test!
        end
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

      let!(:existing_user) { create(:user, email: "forgot@example.com") }

      response "200", "reset instructions sent" do
        schema type: :object, properties: { message: { type: :string } }
        context "when email exists" do
          let(:email_param) { { email: existing_user.email } }

          it "generates a reset token for the user" do
            expect {
              post "/api/v1/auth/forgot_password", params: email_param.to_json, headers: { "Content-Type" => "application/json" }
            }.to change { existing_user.reload.reset_password_token }.from(nil)
          end

          it "returns success message" do
            post "/api/v1/auth/forgot_password", params: email_param.to_json, headers: { "Content-Type" => "application/json" }
            expect(response).to have_http_status(:ok)
            expect(response_body[:message]).to eq("Password reset instructions sent to your email")
          end

          run_test!
        end
      end

      response "404", "email not found" do
        schema type: :object, properties: { error: { type: :string } }
        context "when email does not exist" do
          let(:email_param) { { email: "nonexistent@example.com" } }

          before { post "/api/v1/auth/forgot_password", params: email_param.to_json, headers: { "Content-Type" => "application/json" } }

          it "returns not found status" do
            expect(response).to have_http_status(:not_found)
          end

          it "returns an error message" do
            expect(response_body[:error]).to eq("Email not found")
          end

          run_test!
        end
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

      let!(:user_with_token) { create(:user, :with_reset_token) }

      response "200", "password reset successful" do
        schema type: :object, properties: { message: { type: :string } }
        context "with a valid token and password" do
          let(:reset_params) { { token: user_with_token.reset_password_token, password: "newpassword123" } }

          it "resets the user password" do
            expect {
              post "/api/v1/auth/reset_password", params: reset_params.to_json, headers: { "Content-Type" => "application/json" }
            }.to change { user_with_token.reload.password_digest }
          end

          it "clears the reset token" do
            post "/api/v1/auth/reset_password", params: reset_params.to_json, headers: { "Content-Type" => "application/json" }
            expect(user_with_token.reload.reset_password_token).to be_nil
          end

          it "returns success message" do
            post "/api/v1/auth/reset_password", params: reset_params.to_json, headers: { "Content-Type" => "application/json" }
            expect(response).to have_http_status(:ok)
            expect(response_body[:message]).to eq("Password has been reset successfully")
          end

          run_test!
        end
      end

      response "422", "invalid or expired token / invalid password" do
        schema type: :object, properties: { error: { type: :string } }
        context "with an invalid token" do
          let(:reset_params) { { token: "invalidtoken", password: "newpassword123" } }

          before { post "/api/v1/auth/reset_password", params: reset_params.to_json, headers: { "Content-Type" => "application/json" } }

          it "returns unprocessable entity status" do
            expect(response).to have_http_status(:unprocessable_entity)
          end

          it "returns an error message" do
            expect(response_body[:error]).to eq("Invalid or expired token")
          end

          run_test!
        end

        context "with an expired token" do
          before { user_with_token.update_column(:reset_password_sent_at, 5.hours.ago) }
          let(:reset_params) { { token: user_with_token.reset_password_token, password: "newpassword123" } }

          before { post "/api/v1/auth/reset_password", params: reset_params.to_json, headers: { "Content-Type" => "application/json" } }

          it "returns unprocessable entity status" do
            expect(response).to have_http_status(:unprocessable_entity)
          end

          it "returns an error message" do
            expect(response_body[:error]).to eq("Invalid or expired token")
          end

          run_test! do |response|
            # Optional: Add specific checks here if needed
          end
        end

        context "with an invalid password" do
          let(:reset_params) { { token: user_with_token.reset_password_token, password: "short" } }

          before { post "/api/v1/auth/reset_password", params: reset_params.to_json, headers: { "Content-Type" => "application/json" } }

          it "returns unprocessable entity status" do
            expect(response).to have_http_status(:unprocessable_entity)
          end

          it "returns an error message" do
            expect(response_body[:error]).to eq("Password is too short (minimum is 6 characters)")
          end

          run_test!
        end
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

      let!(:current_user_instance) { create(:user, password: "oldpassword123") }
      let(:Authorization) { "Bearer #{JwtService.encode(user_id: current_user_instance.id)}" }

      response "200", "password changed successfully" do
        schema type: :object, properties: { message: { type: :string } }
        context "with valid current password and new password" do
          let(:password_change) { { current_password: "oldpassword123", new_password: "newpassword456" } }

          it "changes the user password" do
            expect {
              put "/api/v1/auth/change_password", params: password_change.to_json, headers: { "Authorization" => Authorization, "Content-Type" => "application/json" }
            }.to change { current_user_instance.reload.password_digest }
          end

          it "returns success message" do
            put "/api/v1/auth/change_password", params: password_change.to_json, headers: { "Authorization" => Authorization, "Content-Type" => "application/json" }
            expect(response).to have_http_status(:ok)
            expect(response_body[:message]).to eq("Password changed successfully")
          end

          run_test!
        end
      end

      response "401", "unauthorized or incorrect current password" do
        schema type: :object, properties: { error: { type: :string } }
        context "with incorrect current password" do
          let(:password_change) { { current_password: "wrongpassword", new_password: "newpassword456" } }

          before { put "/api/v1/auth/change_password", params: password_change.to_json, headers: { "Authorization" => Authorization, "Content-Type" => "application/json" } }

          it "does not change the password" do
            expect {
              put "/api/v1/auth/change_password", params: password_change.to_json, headers: { "Authorization" => Authorization, "Content-Type" => "application/json" }
            }.not_to change { current_user_instance.reload.password_digest }
          end

          it "returns unauthorized status" do
            expect(response).to have_http_status(:unauthorized)
          end

          it "returns an error message" do
            expect(response_body[:error]).to eq("Current password is incorrect")
          end

          run_test!
        end
      end

      response "422", "invalid new password" do
        schema "$ref" => "#/components/schemas/errors_object"
        context "with invalid new password" do
          let(:password_change) { { current_password: "oldpassword123", new_password: "short" } }

          before { put "/api/v1/auth/change_password", params: password_change.to_json, headers: { "Authorization" => Authorization, "Content-Type" => "application/json" } }

          it "does not change the password" do
            expect {
              put "/api/v1/auth/change_password", params: password_change.to_json, headers: { "Authorization" => Authorization, "Content-Type" => "application/json" }
            }.not_to change { current_user_instance.reload.password_digest }
          end

          it "returns unprocessable entity status" do
            expect(response).to have_http_status(:unprocessable_entity)
          end

          it "returns validation errors" do
            expect(response_body[:errors]).to include("Password is too short (minimum is 6 characters)")
          end

          run_test!
        end
      end
    end
  end
end
