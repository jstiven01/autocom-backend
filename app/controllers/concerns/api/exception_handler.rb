module Api
  module ExceptionHandler
    extend ActiveSupport::Concern

    included do
      rescue_from ActiveRecord::RecordNotFound do |e|
        # lets just set model/id instead of passing DB error message
        render json: { message: "not found: #{e.model} #{e.id}" }, status: :not_found
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render json: { message: e.message }, status: :unprocessable_entity
      end

      rescue_from ActionController::ParameterMissing do |e|
        render json: { message: e.message }, status: :unprocessable_entity
      end

      rescue_from ActiveModel::RangeError do |e|
        render json: { message: e.message }, status: :unprocessable_entity
      end

      rescue_from ActiveRecord::RecordNotSaved do |e|
        render json: { message: e.message }, status: :unprocessable_entity
      end
    end
  end
end
