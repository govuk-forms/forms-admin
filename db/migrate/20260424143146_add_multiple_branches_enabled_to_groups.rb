class AddMultipleBranchesEnabledToGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :groups, :multiple_branches_enabled, :boolean, default: false
  end
end
