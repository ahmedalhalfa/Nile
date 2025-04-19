FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    username { Faker::Internet.unique.username(specifier: 5..15) }
    password { "password123" } # Default password for tests

    # Trait for user with password reset token
    trait :with_reset_token do
      reset_password_token { SecureRandom.urlsafe_base64 }
      reset_password_sent_at { Time.now }
    end
  end
end
