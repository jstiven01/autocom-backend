class VehicleModelSerializer
  include FastJsonapi::ObjectSerializer
  attributes :name
  belongs_to :vehicle_brand

end
