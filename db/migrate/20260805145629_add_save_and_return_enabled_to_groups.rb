class AddSaveAndReturnEnabledToGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :groups, :save_and_return_enabled, :boolean, default: false
  end
end
