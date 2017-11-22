class UpdateDownloadsJob < ActiveJob::Base
  def perform(*args)
    # Call amule to know which downloads are being process. If it does not
    # exist on DB, update (I can use hash)
    Crono.logger.info "Updating downloads job"
  end
end
