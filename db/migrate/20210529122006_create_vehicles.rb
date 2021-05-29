class CreateVehicles < ActiveRecord::Migration[6.1]
  def change
    create_table :vehicles do |t|
      t.string :year
      t.string :mileage
      t.integer :price
      t.references :vehicle_model, null: false, foreign_key: true

      t.timestamps
    end
  end
end
