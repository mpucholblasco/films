class UpdateStat < ApplicationRecord
  before_save :default_values
  def default_values
    self.update_count ||= 0
  end
end
