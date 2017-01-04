require 'sys/filesystem'
include Sys

class FileDisk < ActiveRecord::Base
  RE_FILENAME_ID = /^(?<filename>.+)\s\[(?<id>[^\]]+)\](\.(?<extension>[^.]+))?$/
  RE_FILENAME_EXT = /^(?<filename>.+)\.(?<extension>[^.]+)$/
  belongs_to :disk
  belongs_to :hash_file, class_name: 'HashFile', foreign_key: 'hash_id'
  attr_accessor :original_name
  before_save :fix_filename
  def fix_filename
    self.filename = self.filename.encode('UTF-8', :invalid => :replace, :undef => :replace)
  end

  @original_name = nil

  def self.create_from_filename(filename, internal_filename, disk_id)
    file_disk = FileDisk.new
    file_disk.original_name = internal_filename
    file_disk.filename = internal_filename
    file_disk.size_mb = File.size(filename) / 1024 / 1024
    file_disk.disk_id = disk_id
    file_disk.deleted = false
    return file_disk
  end

  def self.find_using_filename_with_id(filename)
    filename = filename.encode('UTF-8', :invalid => :replace, :undef => :replace)
    filename_id_match = RE_FILENAME_ID.match(filename)
    if filename_id_match
      begin
        return self.find(filename_id_match[:id].to_i(16))
      rescue ActiveRecord::RecordNotFound
      end
    end
    return nil
  end

  def self.search(search, page)
    if search
      search = search.strip
      if not search.empty?
        #[TODO] improve permutation likes
        #[TODO] improve index for filename -> filename, id instead id, filename
        w = nil
        search.split.permutation { |p|
          if w
            w = w + " OR filename like '%#{p.join('%')}%'"
          else
            w = "filename like '%#{p.join('%')}%'"
          end
        }
        matches = where("(" + w + ") AND deleted = false").order('filename')
      else
        matches = all
      end
    else
      matches = all
    end
    matches.paginate :per_page => 50, :page => page
  end

  def append_id_to_filename
    if not self.id.nil? and not self.filename.nil? and not self.filename.empty?
      self.filename = self.filename.encode('UTF-8', :invalid => :replace, :undef => :replace)
      id_in_filename = " [#{self.id.to_s(16)}]"
      filename_id = RE_FILENAME_ID.match(self.filename)
      if filename_id
        new_filename = filename_id[:extension].nil? ? "#{filename_id[:filename]}#{id_in_filename}" : "#{filename_id[:filename]}#{id_in_filename}.#{filename_id[:extension]}"
      else
        filename_extension_match = RE_FILENAME_EXT.match(self.filename)
        if filename_extension_match
          new_filename = "#{filename_extension_match[:filename]}#{id_in_filename}.#{filename_extension_match[:extension]}"
        else # has no extension -> just append the ID
          new_filename = "#{self.filename}#{id_in_filename}"
        end
      end
      self.filename = new_filename
    end
  end

  def copy_extra_data(other)
    if other
      self.id = other.id
      self.score = other.score
    end
  end

  def copy_from_created_from_filename(other)
    if other
      self.filename = other.filename
      self.size_mb = other.size_mb
      self.disk_id = other.disk_id
      self.deleted = other.deleted
    end
  end

  def ==(other)
    not other.nil? and
    other.id == self.id and
    other.filename == self.filename and
    other.size_mb == self.size_mb and
    other.disk_id == self.disk_id and
    other.score == self.score
  end
end
