class VehicleBrandSerializer
  include FastJsonapi::ObjectSerializer
  attributes :name
  has_many :vehicle_models

end
