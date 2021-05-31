# frozen_string_literal: true

module Api
  module V1
    class VehiclesController < ApiController
      def create
        @vehicle = VehicleManager::VehicleCreator
                   .call(vehicle_params)
        render json: serialize_vehicle, status: :created
      rescue VehicleManager::Exceptions::InvalidVehicle => e
        render_error_response messages: e.errors
      end

      def search
        queries = filter_params
        vehicles = Vehicle.by_model(queries['model_name'])
                          .by_brand(queries['brand_name'])
                          .by_year_greater_than(queries['year'])
                          .by_mileage_lower_than(queries['mileage'])
                          .by_price_lower_than(queries['price'])

        render json: serialize_search(vehicles)
      end

      private

      def vehicle_params
        params.require(:vehicle).permit(%i[brand model year price])
      end

      def filter_params
        p = %i[model_name brand_name year mileage price]
        params.permit(p).each do |_key, value|
          value.strip! unless value.is_a?(Array)
        end
      end

      def serialize_vehicle(options = {})
        options[:include] = %i[vehicle_model]
        VehicleSerializer.new(@vehicle, options).serialized_json
      end

      def serialize_search(vehicles)
        vehicles.map do |vehicle|
          hash_result(vehicle)
        end
      end

      def hash_result(vehicle)
        {
          id: vehicle.id,
          model_name: vehicle.vehicle_model.name,
          brand_name: vehicle.vehicle_model.vehicle_brand.name,
          year: vehicle.year,
          mileage: vehicle.mileage,
          price: vehicle.price
        }
      end
    end
  end
end
