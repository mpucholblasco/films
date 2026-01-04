class AddCleanTitleToFileDisks < ActiveRecord::Migration[8.0]
  def change
    add_column :file_disks, :clean_title, :string
    add_index :file_disks, :clean_title,
      using: :gin,
      opclass: :gin_trgm_ops,
      where: "deleted IS NOT TRUE",
      name: "idx_file_disks_clean_title_trgm"
  end
end
