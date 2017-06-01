require 'yaml'

class Disk < ActiveRecord::Base
  has_many :file_disks, :dependent => :delete_all
  enum disk_type: { HD: 1, DVD: 2, CD: 3 }
  validates :name, presence: true
end

class HardDiskInfo < Disk
  DEFAULT_FILE_NAME = 'info'
  def self.read_from_mounted_disk(mount)
    return self.read_from_yaml(File.join(mount,DEFAULT_FILE_NAME))
  end

  def self.read_from_yaml(filename)
    raise IOError.new("File <#{filename}> not found") if not File.exists?(filename)

    begin
      disk_info = YAML::load_file filename
    rescue Psych::SyntaxError
      return self.read_from_old_file(filename)
    end

    disk = HardDiskInfo.new
    disk.name = disk_info['name']
    disk.id = disk_info['id']

    # Obtain disk space
    stat_info = Filesystem.stat(filename)
    disk.total_size = stat_info.block_size * stat_info.blocks
    disk.free_size = stat_info.block_size * stat_info.blocks_free
    return disk
  end

  def self.read_from_old_file(filename)
    raise IOError.new("File <#{filename}> not found") if not File.exists?(filename)
    content = File.open(filename).read
    content.gsub!(/\r\n?/, "\n")
    content_lines = content.lines

    disk = HardDiskInfo.new
    line1_match =  /ID Disco:\s*(\d+)/.match(content_lines[0])
    raise SyntaxError.new("Incorrect info file format") if not line1_match
    disk.id = line1_match[1].to_i
    disk.name = content_lines[1].strip()

    # Obtain disk space
    stat_info = Filesystem.stat(filename)
    disk.total_size = stat_info.block_size * stat_info.blocks
    disk.free_size = stat_info.block_size * stat_info.blocks_free
    return disk
  end

  def initialize
    super
    self.disk_type = :HD
  end

  def store_on_mounted_disk(mount)
    store_as_yaml(File.join(mount,DEFAULT_FILE_NAME))
  end

  def store_as_yaml(filename)
    File.open(filename, "w") do |file|
      file.write({ 'id' => self.id, 'name' => self.name }.to_yaml)
    end
  end

  def ensure_exists
    other_disk = Disk.find(self.id)
    raise Exception.new(I18n.t(:update_error_disk_not_in_db)) if name != other_disk.name or disk_type != other_disk.disk_type
    self.created_at = other_disk.created_at
    self.updated_at = other_disk.updated_at
  end
end
