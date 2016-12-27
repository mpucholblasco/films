namespace :films do
  desc "Initializes a disk to store information and adds it to DB."
  task :initialize_disk, [:mount, :name] => :environment do |_,args|
    logger           = Logger.new(STDOUT)
    logger.level     = Logger::INFO
    Rails.logger     = logger

    raise "Mount path is mandatory" if not args.mount
    raise "Name is mandatory" if not args.name

    logger.info "Initializing disk mounted on <#{args.mount}> with name <#{args.name}>"
    begin
      disk = TasksHelper::HardDiskInfo.read_from_mounted_disk(args.mount)
      logger.info "Found disk info: #{disk.inspect}"
      disk.ensure_exists
      logger.error "Disk already exists. Avoiding initialization"
    rescue ActiveRecord::RecordNotFound
      logger.error "Found disk info, but it does not exist"
    rescue IOError
      logger.info "Disk not found, initializating"

      disk = TasksHelper::HardDiskInfo.new
      disk.name = args.name

      begin
        TasksHelper::HardDiskInfo.transaction do
          disk.save
          disk.store_on_mounted_disk(args.mount)
        end
        logger.info "Disk with name <#{args.name}> initialized correctly with id <#{disk.id}>"
      rescue ActiveRecord::RecordNotUnique => e
        logger.error "Disk with name <#{args.name}> already exists"
      end
    end
  end

  desc "Updates a disk information on DB."
  task :update_disk, [:mount] => :environment do |_,args|
    logger           = Logger.new(STDOUT)
    logger.level     = Logger::INFO
    Rails.logger     = logger

    raise "Mount path is mandatory" if not args.mount

    logger.info "Updating disk mounted on <#{args.mount}>"
    begin
      disk = TasksHelper::HardDiskInfo.read_from_mounted_disk(args.mount)
      disk.ensure_exists
      logger.info "Found disk info: #{disk.inspect}"
      hard_disk_files_info = TasksHelper::HardDiskFilesInfo.new(args.mount, disk.id)
      logger.info "Going to delete <#{hard_disk_files_info.get_files_to_remove.length}> and to add <#{hard_disk_files_info.get_files_to_add.length}>"
      TasksHelper::HardDiskInfo.transaction do
        logger.info "Going to delete <#{hard_disk_files_info.get_files_to_remove.length}>"
        hard_disk_files_info.get_files_to_remove.each do |file|
          file.delete
        end
        logger.info "Going to add <#{hard_disk_files_info.get_files_to_add.length}>"
        hard_disk_files_info.get_files_to_add.each do |file|
          begin
            file.save
          rescue
            file.filename = file.filename.encode('UTF-8', :invalid => :replace, :undef => :replace)
            file.save
          end
        end
        disk_db = Disk.find(disk.id)
        disk_db.last_sync = Time.zone.now
        disk_db.save()
      end
    rescue ActiveRecord::RecordNotFound
      logger.error "Found disk info, but disk does not exist on DB"
    rescue IOError
      logger.error "Disk information not found"
    end
  end
end
