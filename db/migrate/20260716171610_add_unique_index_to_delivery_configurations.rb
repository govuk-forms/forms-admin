class AddUniqueIndexToDeliveryConfigurations < ActiveRecord::Migration[8.1]
  def change
    add_index :delivery_configurations, %i[form_id delivery_method delivery_schedule], unique: true
  end
end
