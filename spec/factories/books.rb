FactoryBot.define do
  factory :book do
    title { Faker::Book.title }
    association :author # Automatically creates an associated author
  end
end
