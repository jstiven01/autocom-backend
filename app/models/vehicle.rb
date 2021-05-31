# frozen_string_literal: true

class Vehicle < ApplicationRecord
  belongs_to :vehicle_model

  validates :price, presence: true
  validates :year, presence: true

  scope :by_model, lambda { |text|
    ransack(vehicle_model_name_cont: text).result
  }

  scope :by_brand, lambda { |text|
    ransack(vehicle_model_vehicle_brand_name_cont: text).result
  }

  scope :by_year_greater_than, ->(year_query) { where('year > ?', year_query) if year_query }

  scope :by_mileage_lower_than, ->(mileage_query) { where('mileage < ?', mileage_query) if mileage_query }

  scope :by_price_lower_than, ->(price_query) { where('price < ?', price_query) if price_query }
end
