class AddNewFieldsToDelayedJobProgress < ActiveRecord::Migration
  def change
    add_column :delayed_job_progresses, :finish_status, :integer
    add_column :delayed_job_progresses, :error_message, :text
  end
end
