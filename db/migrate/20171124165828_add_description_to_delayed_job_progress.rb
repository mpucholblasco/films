class AddDescriptionToDelayedJobProgress < ActiveRecord::Migration
  def change
    add_column :delayed_job_progresses, :description, :string
  end
end
