class CreateHashFiles < ActiveRecord::Migration
  def change
    create_table(:hash_files, :id => false) do |t|
      t.string :id, limit: 64, null: false
      t.decimal :score, precision: 5, scale: 2
      t.timestamps
    end
    execute "ALTER TABLE hash_files ADD PRIMARY KEY (id);"
  end
end
