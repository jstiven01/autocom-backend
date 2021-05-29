# frozen_string_literal: true

class VehicleBrand < ApplicationRecord
  has_many :vehicle_models, dependent: :destroy
end
