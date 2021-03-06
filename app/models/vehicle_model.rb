# frozen_string_literal: true

class VehicleModel < ApplicationRecord
  belongs_to :vehicle_brand
  has_many :vehicles, dependent: :destroy

  validates :name, presence: true
  validates :name, uniqueness: { case_sensitive: false }
end
