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
end
