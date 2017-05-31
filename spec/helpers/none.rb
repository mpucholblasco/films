require 'rails_helper'

RSpec.describe DisksHelper, type: :helper do

  # process
  it "process with no existing disk fails" do
    mount = 'mount'

    # mocking
    allow(File).to receive(:realpath).and_call_original
    allow(File).to receive(:realpath).with(mount).and_return(mount)
    allow(TasksHelper::HardDiskInfo).to receive(:read_from_mounted_disk).with(mount).and_return(disk_info(12345))

    # testing
    hard_disk_files_info = DisksHelper::HardDiskFilesUpdaterInfo.new(mount, 12345)
    expect { hard_disk_files_info.process }.to raise_error(Exception)
  end

  it "process with no changes works correctly" do
    mount = 'mount'

    # mocking
    allow(File).to receive(:realpath).and_call_original
    allow(File).to receive(:realpath).with(mount).and_return(mount)
    disk = disk_info(2)
    allow(TasksHelper::HardDiskInfo).to receive(:read_from_mounted_disk).with(mount).and_return(disk)
    allow(disk).to receive(:ensure_exists).and_return(true)

    # testing
    hard_disk_files_info = DisksHelper::HardDiskFilesUpdaterInfo.new(mount, disk.id)
    allow(hard_disk_files_info).to receive(:process_info).and_return(true)
    hard_disk_files_info.process
  end

  it "process with changes to add works correctly" do
    mount = 'mount'
    filename = 'myfilename'
    file_to_add = file_info(filename)

    # mocking
    allow(File).to receive(:realpath).and_call_original
    allow(File).to receive(:realpath).with(mount).and_return(mount)
    allow(File).to receive(:rename).and_return(true)
    disk = disk_info(2)
    allow(TasksHelper::HardDiskInfo).to receive(:read_from_mounted_disk).with(mount).and_return(disk)
    allow(disk).to receive(:ensure_exists).and_return(true)

    # testing
    hard_disk_files_info = DisksHelper::HardDiskFilesUpdaterInfo.new(mount, disk.id)
    allow(hard_disk_files_info).to receive(:process_info).and_return(true)
    hard_disk_files_info.files_to_add = [ file_to_add ]

    expect {
      hard_disk_files_info.process
    }.to change { FileDisk.count }.by(1)
    expect(file_to_add.id).not_to be_nil
    file_on_db = FileDisk.find(file_to_add.id)
    expect(file_on_db).not_to be_nil
    expect(file_on_db.filename).not_to eq(filename) # because new filename contains id
  end

  it "process with changes to add on DB but not on disk works correctly" do
    mount = 'mount'
    filename = 'myfilename [3039]'
    file_to_add = file_info(filename, 1, 12345)

    # mocking
    allow(File).to receive(:realpath).and_call_original
    allow(File).to receive(:realpath).with(mount).and_return(mount)
    disk = disk_info(2)
    allow(TasksHelper::HardDiskInfo).to receive(:read_from_mounted_disk).with(mount).and_return(disk)
    allow(disk).to receive(:ensure_exists).and_return(true)

    # testing
    hard_disk_files_info = DisksHelper::HardDiskFilesUpdaterInfo.new(mount, disk.id)
    allow(hard_disk_files_info).to receive(:process_info).and_return(true)
    hard_disk_files_info.files_to_add = [ file_to_add ]

    expect {
      hard_disk_files_info.process
    }.to change { FileDisk.count }.by(1)
    expect(file_to_add.id).not_to be_nil
    file_on_db = FileDisk.find(file_to_add.id)
    expect(file_on_db).not_to be_nil
    expect(file_on_db.filename).to eq(filename) # because contains id
  end
  it "process with changes to remove works correctly" do
    mount = 'mount'
    filename = 'myfilename'
    file_to_remove = file_info(filename)
    file_to_remove.save

    # mocking
    allow(File).to receive(:realpath).and_call_original
    allow(File).to receive(:realpath).with(mount).and_return(mount)
    allow(File).to receive(:rename).and_return(true)
    disk = disk_info(2)
    allow(TasksHelper::HardDiskInfo).to receive(:read_from_mounted_disk).with(mount).and_return(disk)
    allow(disk).to receive(:ensure_exists).and_return(true)

    # testing
    hard_disk_files_info = DisksHelper::HardDiskFilesUpdaterInfo.new(mount, disk.id)
    allow(hard_disk_files_info).to receive(:process_info).and_return(true)
    hard_disk_files_info.files_to_remove = [ file_to_remove ]

    expect {
      hard_disk_files_info.process
    }.to change { FileDisk.count }.by(0) # because it's a logical removal, not phisical
    file_on_db = FileDisk.find(file_to_remove.id)
    expect(file_on_db).not_to be_nil
    expect(file_on_db.deleted).to eq(true)
  end

  it "process with changes to update works correctly" do
    mount = 'mount'
    filename = 'myfilename'
    newfilename = 'myotherfilename [3039]'
    file_to_update = file_info(filename, 1, 12345)
    file_to_update.deleted = true
    file_to_update.save

    file_to_update = FileDisk.find(file_to_update.id)
    file_to_update.filename = newfilename

    # mocking
    allow(File).to receive(:realpath).and_call_original
    allow(File).to receive(:realpath).with(mount).and_return(mount)
    allow(File).to receive(:rename).and_return(true)
    disk = disk_info(2)
    allow(TasksHelper::HardDiskInfo).to receive(:read_from_mounted_disk).with(mount).and_return(disk)
    allow(disk).to receive(:ensure_exists).and_return(true)

    # testing
    hard_disk_files_info = DisksHelper::HardDiskFilesUpdaterInfo.new(mount, disk.id)
    allow(hard_disk_files_info).to receive(:process_info).and_return(true)
    hard_disk_files_info.files_to_update = [ file_to_update ]

    expect {
      hard_disk_files_info.process
    }.to change { FileDisk.count }.by(0)
    file_on_db = FileDisk.find(file_to_update.id)
    expect(file_on_db).not_to be_nil
    expect(file_on_db.deleted).to eq(false)
    expect(file_on_db.filename).to eq(newfilename)
  end

  # TODO : when files are present and have the same filename, they are considered to be updated, find out why

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
    result = TasksHelper::HardDiskInfo.new
    result.name = 'disk'
    result.id = 2
    result.total_size = 100
    result.free_size = 100
    result
  end
end
