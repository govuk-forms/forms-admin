class CreateDeliveryConfigurations < ActiveRecord::Migration[8.1]
  def change
    create_table :delivery_configurations do |t|
      t.references :form, null: false, foreign_key: { on_delete: :cascade }
      t.string :delivery_method, null: false
      t.string :delivery_schedule, null: false
      t.string :formats, array: true, null: false, default: []
      t.timestamps
    end
  end
end
