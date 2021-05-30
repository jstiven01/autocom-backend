# frozen_string_literal: true

module VehicleModelManager
  class VehicleModelCreator < ApplicationService
    def initialize(params)
      @params = params
    end

    def call
      vehicle_brand = find_vehicle_brand
      VehicleModel.create!(name: @params['name'], vehicle_brand: vehicle_brand)
    end

    private

    def find_vehicle_brand
      VehicleBrand.where('lower(name) = ?', @params['brand']&.downcase)
                  .first_or_create!(vehicle_brand_param)
    end

    def vehicle_brand_param
      {
        name: @params['brand']
      }
    end
  end
end
