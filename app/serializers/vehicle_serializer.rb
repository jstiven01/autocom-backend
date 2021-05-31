class VehicleSerializer
  include FastJsonapi::ObjectSerializer
  attributes :mileage, :year, :price

  belongs_to :vehicle_model

end
