class CreateExitPagesHeadingAndMarkdownTranslationsForMobilityTableBackend < ActiveRecord::Migration[8.1]
  def change
    create_table :exit_page_translations do |t|
      t.text :heading
      t.text :markdown

      t.string :locale, null: false
      t.references :exit_page, null: false, foreign_key: true, index: false

      t.timestamps null: false
    end

    add_index :exit_page_translations, :locale, name: :index_exit_page_translations_on_locale
    add_index :exit_page_translations, %i[exit_page_id locale], name: :index_exit_page_translations_on_exit_page_id_and_locale, unique: true
  end
end
