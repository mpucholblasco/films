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
      hard_disk_files_info = TasksHelper::HardDiskFilesInfo.new(args.mount)
      hard_disk_files_info.process
    rescue Exception => ex
      logger.error ex.message
    end
  end
end
