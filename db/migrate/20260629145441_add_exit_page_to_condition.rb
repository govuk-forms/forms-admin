class AddExitPageToCondition < ActiveRecord::Migration[8.1]
  def change
    add_reference :conditions, :exit_page, foreign_key: { to_table: :exit_pages }, null: true
  end
end
