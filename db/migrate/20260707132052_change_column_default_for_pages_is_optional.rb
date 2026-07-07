class ChangeColumnDefaultForPagesIsOptional < ActiveRecord::Migration[8.1]
  def change
    change_column_default :pages, :is_optional, from: nil, to: false
  end
end
