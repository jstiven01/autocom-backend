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

      def vehicle_params
        params.require(:vehicle).permit(%i[brand model year price])
      end

      def serialize_vehicle(options = {})
        options[:include] = %i[vehicle_model]
        VehicleSerializer.new(@vehicle, options).serialized_json
      end
    end
  end
end
