class UpdateDiskInformationJob < ActiveJob::Base
  PATHS_TO_PROCESS = [ "Peliculas", "Series", "procesar", "Incoming" ]
  DISK_MOUNT_PATH = '/media/usb/'

  queue_as :update_disk_information

  before_enqueue do |job|
    logger.debug "Initializing delayed job progress with job: #{job.inspect}"
    job_progress = DelayedJobProgress.new
    job_progress.job_id = job.job_id
    job_progress.progress_stage = I18n.t(:starting_progress)
    job_progress.progress_max = 100
    job_progress.save()
  end

  after_perform do |job|
    logger.info "Job #{job_id} finished correctly"
    job_progress = DelayedJobProgress.find(job_id)
    job_progress.upgrade_progress(100, I18n.t(:update_content_finish))
    job_progress.finish_correctly
  end

  rescue_from(StandardError) do |exception|
    logger.info "Job #{job_id} raised exception: #{exception.inspect}"
    job_progress = DelayedJobProgress.find(job_id)
    job_progress.upgrade_progress(100, "Error")
    job_progress.finish_with_errors(exception.message)
  end

  def perform(*args)
    disk_id = args[0]
    logger.info "Updating disk information with disk id = #{disk_id} and job id = #{job_id}"
    job_progress = DelayedJobProgress.find(job_id)
    UpdateDiskInformationJob.process(DISK_MOUNT_PATH, disk_id, job_progress)
  end

  def self.process(mount, disk_id, job_progress)
    disk = nil
    errors = ''
    begin
      mount = File.realpath(mount)
    rescue Exception
      raise StandardError.new(I18n.t(:update_error_disk_not_inserted))
    end

    begin
      disk = HardDiskInfo.read_from_mounted_disk(mount)
      disk.ensure_exists
      disk_id = disk.id if disk_id.nil?
    rescue ActiveRecord::RecordNotFound
      raise StandardError.new(I18n.t(:update_error_disk_not_in_db))
    rescue IOError
      raise StandardError.new(I18n.t(:update_error_disk_information_not_found))
    end

    if disk.id != disk_id
      raise StandardError.new(I18n.t(:update_error_inserted_disk_is_not_updating_one, :inserted_disk => disk.id, :updating_disk => disk_id))
    end

    job_progress.upgrade_progress(0, I18n.t(:update_content_obtaining_disk_info))

    hard_disk_files_updater_info = DisksHelper::HardDiskFilesUpdaterInfo.new(mount, disk_id)
    PATHS_TO_PROCESS.each do |path|
      Dir.glob("#{mount}/#{path}/**/*").select{ |e| File.file? e }.each do |file|
        hard_disk_files_updater_info.add_file(file)
      end
    end

    self.remove_files hard_disk_files_updater_info.get_files_to_remove, job_progress
    self.add_files mount, hard_disk_files_updater_info.get_files_to_add, job_progress
    self.update_files mount, hard_disk_files_updater_info.get_files_to_update, job_progress

    disk_db = Disk.find(disk.id)
    disk_db.last_sync = Time.zone.now
    disk_db.total_size = disk.total_size
    disk_db.free_size = disk.free_size
    disk_db.save()

    # Found problems with external drives and file renaming, trying with a sync
    system("sync")

    if not errors.empty?
      raise StandardError.new(errors)
    end
  end

  def self.remove_files(files_to_remove, job_progress)
    # Mark deleted files as deleted
    job_progress.upgrade_progress(5, I18n.t(:update_content_deleting_files, :files_number => files_to_remove.length ))
    FileDisk.transaction do
      Rails.logger.info "Going to delete <#{files_to_remove.length}>"
      files_to_remove.each do |file|
        Rails.logger.debug "Deleting file #{file.inspect}"
        file.deleted = true
        file.save
      end
    end
  end

  def self.add_files(mount, files_to_add, job_progress)
    job_progress.upgrade_progress(10, I18n.t(:update_content_adding_files, :files_number => files_to_add.length ))
    Rails.logger.info "Going to add <#{files_to_add.length}>"
    added_files = 0
    files_to_add.each do |file|
      begin
        FileDisk.transaction do
          Rails.logger.debug "Adding file #{file.inspect}"
          file.save
          file.append_id_to_filename
          file.save
          File.rename("#{mount}/#{file.original_name}", "#{mount}/#{file.filename}") if file.original_name != file.filename
          added_files += 1
          job_progress.upgrade_progress(10 + (45 * added_files / files_to_add.length))
        end
      rescue IOError => ex
        errors << I18n.t(:update_error_couldnt_rename_file, :original_name => file.original_name, :target_name => file.filename) << '(' << ex.message << ')' << '\n'
        Rails.logger.debug "Error adding file #{file.inspect}. Reason: #{ex}"
      rescue ActiveRecord::RecordNotUnique => ex
        errors << I18n.t(:update_error_duplicated_file, :duplicated_filename => file.filename) << '\n'
        Rails.logger.debug "Error adding file #{file.inspect}. Reason: #{ex}"
      end
    end
  end

  def self.update_files(mount, files_to_update, job_progress)
    job_progress.upgrade_progress(55, I18n.t(:update_content_updating_files, :files_number => files_to_update.length ))
    Rails.logger.info "Going to update <#{files_to_update.length}>"
    updated_files = 0
    files_to_update.each do |file|
      begin
        FileDisk.transaction do
          Rails.logger.debug "Updating file #{file.inspect}"
          file.deleted = false
          file.save
          File.rename("#{mount}/#{file.original_name}", "#{mount}/#{file.filename}") if file.original_name != file.filename
          updated_files += 1
          job_progress.upgrade_progress(55 + (45 * updated_files / files_to_update.length))
        end
      rescue IOError => ex
        errors << I18n.t(:update_error_couldnt_rename_file, :original_name => file.original_name, :target_name => file.filename) << '(' << ex.message << ')' << '\n'
        Rails.logger.debug "Error updating file #{file.inspect}. Reason: #{ex}"
      rescue ActiveRecord::RecordNotUnique => ex
        errors << I18n.t(:update_error_duplicated_file, :duplicated_filename => file.filename) << '\n'
        Rails.logger.debug "Error updating file #{file.inspect}. Reason: #{ex}"
      end
    end
  end
end
