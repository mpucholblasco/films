require 'rails_helper'

RSpec.describe UpdateDiskInformationJob, type: :job do
  it "remove_files works correctly" do
    file_to_remove = file_info('myfilename')
    file_to_remove.save

    expect {
      UpdateDiskInformationJob.remove_files([ file_to_remove ], DelayedJobProgress.new)
    }.to change { FileDisk.count }.by(0) # because it's a logical removal, not phisical
    file_on_db = FileDisk.find(file_to_remove.id)
    expect(file_on_db).not_to be_nil
    expect(file_on_db.deleted).to eq(true)
  end

  it "add_files changing filename works correctly" do
    filename = 'myfilename'
    file_to_add = file_info(filename)

    # mocking
    allow(File).to receive(:rename).and_return(true)

    expect {
      UpdateDiskInformationJob.add_files('mount', [ file_to_add ], DelayedJobProgress.new)
    }.to change { FileDisk.count }.by(1)
    expect(file_to_add.id).not_to be_nil
    file_on_db = FileDisk.find(file_to_add.id)
    expect(file_on_db).not_to be_nil
    expect(file_on_db.filename).not_to eq(filename) # because new filename contains id
  end

  it "add_files without changing filename works correctly" do
    filename = 'myfilename [3039]'
    file_to_add = file_info(filename, 1, 12345)

    expect {
      UpdateDiskInformationJob.add_files('mount', [ file_to_add ], DelayedJobProgress.new)
    }.to change { FileDisk.count }.by(1)
    expect(file_to_add.id).not_to be_nil
    file_on_db = FileDisk.find(file_to_add.id)
    expect(file_on_db).not_to be_nil
    expect(file_on_db.filename).to eq(filename) # because contains id
  end

  it "update_files works correctly" do
    filename = 'myfilename'
    newfilename = 'myotherfilename [3039]'
    file_to_update = file_info(filename, 1, 12345)
    file_to_update.deleted = true
    file_to_update.save

    file_to_update = FileDisk.find(file_to_update.id)
    file_to_update.filename = newfilename

    # mocking
    allow(File).to receive(:rename).and_return(true)

    expect {
      UpdateDiskInformationJob.update_files('mount', [ file_to_update ], DelayedJobProgress.new)
    }.to change { FileDisk.count }.by(0)
    file_on_db = FileDisk.find(file_to_update.id)
    expect(file_on_db).not_to be_nil
    expect(file_on_db.deleted).to eq(false)
    expect(file_on_db.filename).to eq(newfilename)
  end

  it "process with no existing disk fails" do
    mount = 'mount'

    # mocking
    allow(File).to receive(:realpath).and_call_original
    allow(File).to receive(:realpath).with(mount).and_return(mount)
    allow(HardDiskInfo).to receive(:read_from_mounted_disk).with(mount).and_return(disk_info(12345))

    # testing
    expect {
      UpdateDiskInformationJob.process(mount, 2, DelayedJobProgress.new)
    }.to raise_error(Exception)
  end

  it "process with no changes works correctly" do
    mount = 'mount'

    # mocking
    allow(Dir).to receive(:glob).and_return([])
    allow(Dir).to receive(:glob).with("#{mount}/Peliculas/**/*").and_return([])
    allow(File).to receive(:realpath).and_call_original
    allow(File).to receive(:realpath).with(mount).and_return(mount)
    disk = disk_info(2)
    allow(HardDiskInfo).to receive(:read_from_mounted_disk).with(mount).and_return(disk)
    allow(disk).to receive(:ensure_exists).and_return(true)

    # testing
    UpdateDiskInformationJob.process(mount, 2, DelayedJobProgress.new)
  end

  private

  def file_info(filename, disk_id = 1, id = nil)
    result = FileDisk.new
    result.id = id
    result.original_name = filename
    result.filename = filename
    result.size_mb = 100
    result.disk_id = disk_id
    result.deleted = false
    result
  end

  def disk_info(disk_id)
    result = HardDiskInfo.new
    result.name = 'disk'
    result.id = 2
    result.total_size = 100
    result.free_size = 100
    result
  end
end
