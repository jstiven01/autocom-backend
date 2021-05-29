# frozen_string_literal: true

FactoryBot.define do
  factory :vehicle_brand do
    name { Faker::Lorem.word }
  end
end
