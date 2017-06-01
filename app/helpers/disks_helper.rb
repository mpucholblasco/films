module DisksHelper
  class HardDiskFilesUpdaterInfo
    def initialize(mount, disk_id)
      @mount = mount
      @disk_id = disk_id
      @files_to_add = []
      @files_to_update = []
      @ids_updated = Set.new
      @files_to_update = []
      @files_to_add = []
    end

    def get_files_to_add
      @files_to_add
    end

    def get_files_to_update
      @files_to_update
    end

    def get_files_to_remove
      @files_on_db ||= get_files_on_db
      @files_on_db.values.select{ |file|
        not @ids_updated.include?(file.id)
      }
    end

    def add_file(file)
      @files_on_db ||= get_files_on_db
      raise Exception.new("File #{file} does not start by mount path #{@mount}") if !file.start_with?(@mount)

      internal_filename = file[(@mount.length+1)..-1]
      file_on_disk_db = @files_on_db[internal_filename]
      file_info = FileDisk.create_from_filename(file, internal_filename, @disk_id)
      file_on_db = FileDisk.find_using_filename_with_id(internal_filename)

      if file_on_db
        file_on_db.copy_from_created_from_filename(file_info)
        @files_on_db.delete(internal_filename)
        if file_info != file_on_disk_db
          file_on_db.append_id_to_filename
          @files_to_update << file_on_db
          @ids_updated.add(file_on_db.id)
        end
      elsif file_on_disk_db
        file_on_disk_db.copy_from_created_from_filename(file_info)
        file_on_disk_db.append_id_to_filename
        @files_on_db.delete(internal_filename)
        @files_to_update << file_on_disk_db
        @ids_updated.add(file_on_disk_db.id)
      else # not present neither on DB nor disk_DB -> it's new
        @files_to_add << file_info
      end
    end

    private

    def get_files_on_db
      files_on_db = {}
      Disk.find(@disk_id).file_disks.each do |file_disk|
        files_on_db[file_disk.filename] = file_disk
      end
      files_on_db
    end
  end
end
