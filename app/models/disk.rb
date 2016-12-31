class Disk < ActiveRecord::Base
  has_many :file_disks, :dependent => :delete_all
  enum disk_type: { HD: 1, DVD: 2, CD: 3 }
  validates :name, presence: true
end
