class ChangeDataTypeColumnsVehicles < ActiveRecord::Migration[6.1]
  def up
    change_column :vehicles, :year, :integer
    change_column :vehicles, :mileage, :integer
  end
  def down
    change_column :vehicles, :year, :string
    change_column :vehicles, :mileage, :string
  end
end
