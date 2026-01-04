class SetSimilarityThreshold < ActiveRecord::Migration[8.0]
  def up
    execute "ALTER DATABASE #{connection.current_database} SET pg_trgm.similarity_threshold = 0.7"
  end

  def down
    execute "ALTER DATABASE #{connection.current_database} SET pg_trgm.similarity_threshold = 0.3"
  end
end
