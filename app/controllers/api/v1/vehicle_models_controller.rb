# frozen_string_literal: true

module Api
  module V1
    class VehicleModelsController < ApiController
      def create
        @vehicle_model = VehicleModelManager::VehicleModelCreator
                         .call(vehicle_model_params)
        render json: serialize_vehicle_model, status: :created
      rescue VehicleModelManager::Exceptions::InvalidVehicleModel => e
        render_error_response messages: e.errors
      end

      def vehicle_model_params
        params.require(:vehicle_model).permit(%i[name brand])
      end

      def serialize_vehicle_model(options = {})
        options[:include] = %i[vehicle_brand]
        VehicleModelSerializer.new(@vehicle_model, options).serialized_json
      end
    end
  end
end
