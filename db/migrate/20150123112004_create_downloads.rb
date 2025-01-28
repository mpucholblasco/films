class CreateDownloads < ActiveRecord::Migration[8.0]
  def change
    create_table :downloads do |t|
      t.string :filename
      t.float :percentage

      t.timestamps null: false
    end
  end
end
