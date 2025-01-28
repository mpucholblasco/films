class CreateJobs < ActiveRecord::Migration[8.0]
  def change
    create_enum :job_finish_status, [ "UNFINISHED", "FINISHED_WITH_ERRORS", "FINISHED_CORRECTLY", "CANCELLED" ]

    create_table :jobs, id: :string do |t|
      t.integer :progress_max, null: false, default: 100
      t.integer :progress, null: false, default: 0
      t.string :progress_stage
      t.enum :finish_status, enum_type: :job_finish_status, default: "UNFINISHED", null: false
      t.text :error_message
      t.string :description

      t.timestamps null: false
    end
  end
end
