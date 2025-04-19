FactoryBot.define do
  factory :author do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    age { Faker::Number.between(from: 20, to: 80) }
  end
end
