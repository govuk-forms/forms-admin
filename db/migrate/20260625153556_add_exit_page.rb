class AddExitPage < ActiveRecord::Migration[8.1]
  def change
    create_table :exit_pages do |t|
      t.text :heading, comment: "The title used for the exit page "
      t.text :markdown, comment: "The body content in markdown format"
      t.belongs_to :question_page, foreign_key: { to_table: :pages, on_delete: :cascade }, null: false, comment: "The page that the exit page belongs to"
      t.timestamps
    end
  end
end
