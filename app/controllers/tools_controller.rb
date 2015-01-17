class ToolsController < ApplicationController
  def index
  end

  def find_duplicates
    logger.info "Finding duplicates"
    @duplicates = get_file_disk_duplicates
    logger.info "Found #{@duplicates.length} duplicates"
  end

  private

  def get_file_disk_duplicates
    filenames_found = {}
    FileDisk.find_each do |file_disk|
      basename = File.basename(file_disk.filename)
      if ! filenames_found.has_key?(basename)
      filenames_found[basename] = []
      end
      filenames_found[basename] << file_disk
    end

    filenames_found.reject!{ |k,v| v.length == 1}
  end

end
