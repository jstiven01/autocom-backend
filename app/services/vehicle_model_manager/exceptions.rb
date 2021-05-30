# frozen_string_literal: true

module VehicleModelManager
  module Exceptions
    class InvalidVehicleModel < StandardError
      attr_accessor :errors

      def initialize(errors)
        @errors = errors
        super()
      end
    end
  end
end
