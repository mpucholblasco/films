class CreateUpdateStats < ActiveRecord::Migration[8.0]
  def change
    create_table :update_stats do |t|
      t.string :name
      t.integer :update_count

      t.timestamps null: false
    end
    add_index :update_stats, :name, unique: true
  end
end
