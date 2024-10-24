class CreateInsights < ActiveRecord::Migration[7.0]
  def change
    create_table :insights do |t|
      t.references :info_request, foreign_key: true
      t.string :model
      t.text :template
      t.jsonb :output

      t.timestamps
    end
  end
end
