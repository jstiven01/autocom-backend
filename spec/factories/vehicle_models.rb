# frozen_string_literal: true

FactoryBot.define do
  factory :vehicle_model do
    name { Faker::Lorem.word }
    association :vehicle_brand
  end
end
