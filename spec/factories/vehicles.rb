# frozen_string_literal: true

FactoryBot.define do
  factory :vehicle do
    association :vehicle_model
    year { rand(2000..2020) }
    price { rand(2000..200_000) }
    mileage { rand(200..200_000) }
  end
end
