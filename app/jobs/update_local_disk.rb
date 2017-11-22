class UpdateLocalDiskJob < ActiveJob::Base
  def perform(*args)
    # Read local disks from DB (create a table with disk ID and paths to review)
    # For each disk ID, navigate thru all paths and then update disk space
    Crono.logger.info "Updating local disk, which has ID #{Films::Application.config.LocalDiskID}"
  end
end
