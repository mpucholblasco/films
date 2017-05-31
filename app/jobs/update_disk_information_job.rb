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
    logger.info "After perform job: #{job.inspect}"
    DelayedJobProgress.find(job_id).finish_process
  end

  rescue_from(Exception) do |exception|
    logger.info "Rescue from exception: #{exception.inspect}"
  end

  def perform(*args)
    # Do something later
    logger.info "Updating disk information with params #{args.inspect}"
    logger.debug "Performing UpdateDiskInformationJob with params #{args.inspect}"
    logger.debug "Job id: #{job_id}"
    job_progress = DelayedJobProgress.find(job_id)
    c = 0
    10.times {
      logger.debug "Sleeping 3 seconds at #{c}"
      job_progress.upgrade_progress(c)
      if c > 60
        10 / 0 # division by 0
        job_progress.progress_stage = 'my new stage'
        job_progress.save
      end
      sleep 3
      c += 10
    }
  end

  def process(mount, disk_id, job_progress)
    disk = nil
    errors = ''
    mount = File.realpath(mount)
    begin
      disk = TasksHelper::HardDiskInfo.read_from_mounted_disk(mount)
      disk.ensure_exists
      disk_id = disk.id if disk_id.nil?
    rescue ActiveRecord::RecordNotFound
      raise Exception.new(I18n.t(:update_error_disk_not_in_db))
    rescue IOError
      raise Exception.new(I18n.t(:update_error_disk_information_not_found))
    end

    if disk.id != disk_id
      raise Exception.new(I18n.t(:update_error_inserted_disk_is_not_updating_one, :inserted_disk => disk.id, :updating_disk => disk_id))
    end

    (files_to_remove, files_to_add, files_to_update) = process_info(mount, disk_id)

    # Mark deleted files as deleted
    FileDisk.transaction do
      Rails.logger.info "Going to delete <#{files_to_remove.length}>"
      files_to_remove.each do |file|
        Rails.logger.debug "Deleting file #{file.inspect}"
        file.deleted = true
        file.save
      end
    end

    Rails.logger.info "Going to add <#{@files_to_add.length}>"
    files_to_add.each do |file|
      begin
        FileDisk.transaction do
          Rails.logger.debug "Adding file #{file.inspect}"
          file.save
          file.append_id_to_filename
          file.save
          File.rename("#{mount}/#{file.original_name}", "#{mount}/#{file.filename}") if file.original_name != file.filename
        end
      rescue IOError => ex
        errors << I18n.t(:update_error_couldnt_rename_file, :original_name => file.original_name, :target_name => file.filename) << '(' << ex.message << ')' << '\n'
        Rails.logger.debug "Error adding file #{file.inspect}. Reason: #{ex}"
      rescue ActiveRecord::RecordNotUnique => ex
        errors << I18n.t(:update_error_duplicated_file, :duplicated_filename => file.filename) << '\n'
        Rails.logger.debug "Error adding file #{file.inspect}. Reason: #{ex}"
      end
    end

    Rails.logger.info "Going to update <#{files_to_update.length}>"
    files_to_update.each do |file|
      begin
        FileDisk.transaction do
          Rails.logger.debug "Updating file #{file.inspect}"
          file.deleted = false
          file.save
          File.rename("#{mount}/#{file.original_name}", "#{mount}/#{file.filename}") if file.original_name != file.filename
        end
      rescue IOError => ex
        errors << I18n.t(:update_error_couldnt_rename_file, :original_name => file.original_name, :target_name => file.filename) << '(' << ex.message << ')' << '\n'
        Rails.logger.debug "Error updating file #{file.inspect}. Reason: #{ex}"
      rescue ActiveRecord::RecordNotUnique => ex
        errors << I18n.t(:update_error_duplicated_file, :duplicated_filename => file.filename) << '\n'
        Rails.logger.debug "Error updating file #{file.inspect}. Reason: #{ex}"
      end
    end

    disk_db = Disk.find(disk.id)
    disk_db.last_sync = Time.zone.now
    disk_db.total_size = disk.total_size
    disk_db.free_size = disk.free_size
    disk_db.save()

    # Found problems with external drives and file renaming, trying with a sync
    system("sync")

    if not errors.empty?
      raise Exception.new(errors)
    end
  end

  private

  def get_files_on_db(disk_id)
    files_on_db = {}
    Disk.find(disk_id).file_disks.each do |file_disk|
      files_on_db[file_disk.filename] = file_disk
    end
    return files_on_db
  end

  def process_info(mount, disk_id)
    files_on_db = get_files_on_db
    ids_updated = Set.new
    files_to_update = []
    files_to_add = []

    PATHS_TO_PROCESS.each do |path|
      files = Dir.glob("#{mount}/#{path}/**/*").select{ |e| File.file? e }
      files.each do |file|
        internal_filename = file[(mount.length+1)..-1]
        file_on_disk_db = files_on_db[internal_filename]
        file_info = FileDisk.create_from_filename(file, internal_filename, disk_id)
        file_on_db = FileDisk.find_using_filename_with_id(internal_filename)

        if file_on_db
          file_on_db.copy_from_created_from_filename(file_info)
          files_on_db.delete(internal_filename)
          if file_info != file_on_disk_db
            file_on_db.append_id_to_filename
            files_to_update << file_on_db
            ids_updated.add(file_on_db.id)
          end
        elsif file_on_disk_db
          file_on_disk_db.copy_from_created_from_filename(file_info)
          file_on_disk_db.append_id_to_filename
          files_on_db.delete(internal_filename)
          files_to_update << file_on_disk_db
          ids_updated.add(file_on_disk_db.id)
        else # not present neither on DB nor disk_DB -> it's new
          files_to_add << file_info
        end
      end
    end
    files_to_remove = files_on_db.values.select{ |file|
      not ids_updated.include?(file.id)
    }
    return [files_to_add, files_to_remove, files_to_update]
  end
end
