class CreateDelayedJobProgresses < ActiveRecord::Migration
  def change
    create_table :delayed_job_progresses, :id => false do |t|
      t.string :job_id, null: false
      t.integer :progress_max, null: false
      t.integer :progress, null: false
      t.string :progress_stage

      t.timestamps null: false
    end
    execute "ALTER TABLE delayed_job_progresses ADD PRIMARY KEY (job_id);"
  end
end
