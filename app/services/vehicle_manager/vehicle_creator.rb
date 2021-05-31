# frozen_string_literal: true

module VehicleManager
  class VehicleCreator < ApplicationService
    def initialize(params)
      @params = params
    end

    def call
      vehicle_model = find_vehicle_model
      Vehicle.create!(year: @params['year'], price: @params['price'], vehicle_model: vehicle_model)
    end

    private

    def find_vehicle_model
      vehicle_model = VehicleModel.where('lower(name) = ?', @params['model']&.downcase).first
      vehicle_model || VehicleModelManager::VehicleModelCreator
        .call(vehicle_model_params)
    end

    def vehicle_model_params
      {
        'name' => @params['model'],
        'brand' => @params['brand']
      }
    end
  end
end
