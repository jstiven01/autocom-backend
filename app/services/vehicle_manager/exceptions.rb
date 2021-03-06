# frozen_string_literal: true

module VehicleManager
  module Exceptions
    class InvalidVehicle < StandardError
      attr_accessor :errors

      def initialize(errors)
        @errors = errors
        super()
      end
    end
  end
end
