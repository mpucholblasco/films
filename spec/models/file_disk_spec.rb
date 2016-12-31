require 'rails_helper'

RSpec.describe FileDisk, :type => :model do
  it "should find using filename_with_id if FileDisk exists and has no extension" do
    file_disk = FileDisk.find_using_filename_with_id('my filename [1]')
    expect(file_disk).not_to be_nil
  end

  it "should find using filename_with_id if FileDisk exists and has extension" do
    file_disk = FileDisk.find_using_filename_with_id('my filename [1].ext')
    expect(file_disk).not_to be_nil
  end

  it "should find using filename_with_id if FileDisk exists and hex is valid has extension" do
    file_disk = FileDisk.find_using_filename_with_id('my filename [ab].ext')
    expect(file_disk).not_to be_nil
  end

  it "should not find using filename_with_id if FileDisk does not exists" do
    file_disk = FileDisk.find_using_filename_with_id('my filename [ac].ext')
    expect(file_disk).to be_nil
  end

  it "should not find using filename_with_id if filename does not contain id" do
    file_disk = FileDisk.find_using_filename_with_id('my filename.ext')
    expect(file_disk).to be_nil
  end

  # append_id_to_filename
  it "id not appended if it's nil" do
    file_disk = FileDisk.new
    file_disk.append_id_to_filename
    expect(file_disk.filename).to be_nil
  end

  it "id not appended if filename is nil" do
    file_disk = FileDisk.new
    file_disk.id = 171
    file_disk.append_id_to_filename
    expect(file_disk.filename).to be_nil
  end

  it "id converted to hex correctly and filename without extension" do
    file_disk = FileDisk.new
    file_disk.id = 171
    file_disk.filename = 'my filename'
    file_disk.append_id_to_filename
    expect(file_disk.filename).to eq('my filename [ab]')
  end

  it "id converted to hex correctly and filename has extension" do
    file_disk = FileDisk.new
    file_disk.id = 171
    file_disk.filename = 'my filename.ext'
    file_disk.append_id_to_filename
    expect(file_disk.filename).to eq('my filename [ab].ext')
  end

  it "id converted to hex correctly and filename without extension but with id" do
    file_disk = FileDisk.new
    file_disk.id = 171
    file_disk.filename = 'my filename [1]'
    file_disk.append_id_to_filename
    expect(file_disk.filename).to eq('my filename [ab]')
  end

  it "id converted to hex correctly and filename has extension but with id" do
    file_disk = FileDisk.new
    file_disk.id = 171
    file_disk.filename = 'my filename [1].ext'
    file_disk.append_id_to_filename
    expect(file_disk.filename).to eq('my filename [ab].ext')
  end

  # create_from_filename
  it "create_from_filename gets correct information" do
    allow(File).to receive(:size).with('filename').and_return(12345678)
    file_disk = FileDisk.create_from_filename('filename', 'internal_filename', 1)
    expect(file_disk.id).to be_nil
    expect(file_disk.original_name).to eq('internal_filename')
    expect(file_disk.filename).to eq('internal_filename')
    expect(file_disk.size_mb).to eq(11)
    expect(file_disk.disk_id).to eq(1)
    expect(file_disk.deleted).to eq(false)
  end

  # non-utf-8 encoding
  it "find_using_filename_with_id should work with non-utf-8 characters" do
    file_disk = FileDisk.find_using_filename_with_id(non_utf8_filename)
    expect(file_disk).to be_nil
  end

  private

  def non_utf8_filename
    non_utf8_filename_hex = '496e636f6d696e672f547261732e6c612e6de17363617261202832303135292e5b48445269702e587669442d4143332e352e315d32332c39382e617669'
    non_utf8_filename_hex.scan(/../).map { |x| x.hex.chr }.join
  end
end
