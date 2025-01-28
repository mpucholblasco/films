require "yaml"

class Disk < ApplicationRecord
  enum :disk_type, {
    HD: "HD", DVD: "DVD", CD: "CD"
  }, prefix: true

  has_many :file_disks, dependent: :delete_all
  validates :name, presence: true
  paginates_per 50
  broadcasts_refreshes
end
