# frozen_string_literal: true

class VehicleBrand < ApplicationRecord
  has_many :vehicle_models, dependent: :destroy

  validates :name, presence: true
  validates :name, uniqueness: { case_sensitive: false }
end
