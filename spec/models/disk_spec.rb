require 'rails_helper'

RSpec.describe Disk, type: :model do
  it "should not save disk without name" do
    disk = Disk.new
    expect(disk).to be_invalid
  end
end
