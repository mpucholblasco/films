class HashFile < ActiveRecord::Base
  has_many :file_disks, dependent: :nullify, foreign_key: 'hash_id'
  validates_uniqueness_of :id
end
