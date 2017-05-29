require 'rails_helper'

RSpec.describe TasksHelper, type: :helper do
  it "creation works as expected and obtains real path" do
    allow(File).to receive(:realpath).with('mount_path').and_return('mount_path')
    hard_disk_files_info = TasksHelper::HardDiskFilesInfo.new('mount_path', 1)
    expect(hard_disk_files_info).not_to be_nil
  end

  # process_info
  it "process_info should add a new file if DB is empty and file does not contain ID" do
    mount = 'mount'
    file_without_mount = 'Peliculas/file_to_add'
    file_with_mount = "#{mount}/#{file_without_mount}"
    file_to_add = file_info(file_without_mount)

    # mocking
    allow(File).to receive(:realpath).and_call_original
    allow(File).to receive(:realpath).with(mount).and_return(mount)
    allow(Dir).to receive(:glob).and_return([])
    allow(Dir).to receive(:glob).with("#{mount}/Peliculas/**/*").and_return([ file_with_mount ])
    allow(File).to receive(:file?).and_call_original
    allow(File).to receive(:file?).with(file_with_mount).and_return(true)
    allow(FileDisk).to receive(:find_using_filename_with_id).and_return(nil)
    allow(FileDisk).to receive(:create_from_filename).with(file_with_mount, file_without_mount, 1).and_return(file_to_add)

    # testing
    hard_disk_files_info = TasksHelper::HardDiskFilesInfo.new(mount, 1)
    allow(hard_disk_files_info).to receive(:get_files_on_db).and_return({})
    hard_disk_files_info.send(:process_info)
    expect(hard_disk_files_info.get_files_to_add.length).to eq(1)
    expect(hard_disk_files_info.get_files_to_add[0]).to eq(file_to_add)
    expect(hard_disk_files_info.get_files_to_remove.length).to eq(0)
    expect(hard_disk_files_info.get_files_to_update.length).to eq(0)
  end

  it "process_info should add a new file if DB is empty and file contains ID" do
    mount = 'mount'
    file_without_mount = 'Peliculas/file_to_add [5]'
    file_with_mount = "#{mount}/#{file_without_mount}"
    file_to_add = file_info(file_without_mount, 1)

    # mocking
    allow(File).to receive(:realpath).and_call_original
    allow(File).to receive(:realpath).with(mount).and_return(mount)
    allow(Dir).to receive(:glob).and_return([])
    allow(Dir).to receive(:glob).with("#{mount}/Peliculas/**/*").and_return([ file_with_mount ])
    allow(File).to receive(:file?).and_call_original
    allow(File).to receive(:file?).with(file_with_mount).and_return(true)
    allow(FileDisk).to receive(:find_using_filename_with_id).and_return(nil)
    allow(FileDisk).to receive(:create_from_filename).with(file_with_mount, file_without_mount, 1).and_return(file_to_add)

    # testing
    hard_disk_files_info = TasksHelper::HardDiskFilesInfo.new(mount, 1)
    allow(hard_disk_files_info).to receive(:get_files_on_db).and_return({})
    hard_disk_files_info.send(:process_info)
    expect(hard_disk_files_info.get_files_to_add.length).to eq(1)
    expect(hard_disk_files_info.get_files_to_add[0]).to eq(file_to_add)
    expect(hard_disk_files_info.get_files_to_remove.length).to eq(0)
    expect(hard_disk_files_info.get_files_to_update.length).to eq(0)
  end


  it "process_info should update an existing file because it's on DB and disk is different" do
    mount = 'mount'
    file_without_mount = 'Peliculas/file_to_modify [1]'
    file_with_mount = "#{mount}/#{file_without_mount}"
    file_to_update = file_info(file_without_mount, 2)

    # mocking
    allow(File).to receive(:realpath).and_call_original
    allow(File).to receive(:realpath).with(mount).and_return(mount)
    allow(Dir).to receive(:glob).and_return([])
    allow(Dir).to receive(:glob).with("#{mount}/Peliculas/**/*").and_return([ file_with_mount ])
    allow(File).to receive(:file?).and_call_original
    allow(File).to receive(:file?).with(file_with_mount).and_return(true)
    allow(FileDisk).to receive(:find_using_filename_with_id).and_return(file_info(file_without_mount, 1))
    allow(FileDisk).to receive(:create_from_filename).with(file_with_mount, file_without_mount, 2).and_return(file_to_update)

    # testing
    hard_disk_files_info = TasksHelper::HardDiskFilesInfo.new(mount, 2)
    allow(hard_disk_files_info).to receive(:get_files_on_db).and_return({})
    hard_disk_files_info.send(:process_info)
    expect(hard_disk_files_info.get_files_to_add.length).to eq(0)
    expect(hard_disk_files_info.get_files_to_remove.length).to eq(0)
    expect(hard_disk_files_info.get_files_to_update.length).to eq(1)
    expect(hard_disk_files_info.get_files_to_update[0]).to eq(file_to_update)
  end

  it "process_info should update an existing file because it's on DB, disk is the same, but the file is not in the same path" do
    mount = 'mount'
    file_without_mount = 'Peliculas/file_to_modify [1]'
    file_with_mount = "#{mount}/#{file_without_mount}"
    file_to_update = file_info(file_without_mount, 2, 1)
    file_on_db_filename = 'anotherplace/another_filename [1].ext'
    file_on_db = file_info("#{file_on_db_filename}", 2, 1)

    # mocking
    allow(File).to receive(:realpath).and_call_original
    allow(File).to receive(:realpath).with(mount).and_return(mount)
    allow(Dir).to receive(:glob).and_return([])
    allow(Dir).to receive(:glob).with("#{mount}/Peliculas/**/*").and_return([ file_with_mount ])
    allow(File).to receive(:file?).and_call_original
    allow(File).to receive(:file?).with(file_with_mount).and_return(true)
    allow(FileDisk).to receive(:find_using_filename_with_id).and_return(file_on_db)
    allow(FileDisk).to receive(:create_from_filename).with(file_with_mount, file_without_mount, 2).and_return(file_to_update)

    # testing
    hard_disk_files_info = TasksHelper::HardDiskFilesInfo.new(mount, 2)
    allow(hard_disk_files_info).to receive(:get_files_on_db).and_return({ file_on_db_filename => file_on_db})
    hard_disk_files_info.send(:process_info)
    expect(hard_disk_files_info.get_files_to_add.length).to eq(0)
    expect(hard_disk_files_info.get_files_to_remove.length).to eq(0)
    expect(hard_disk_files_info.get_files_to_update.length).to eq(1)
    expect(hard_disk_files_info.get_files_to_update[0]).to eq(file_to_update)
  end

  it "process_info should not update if no changes" do
    mount = 'mount'
    file_without_mount = 'Peliculas/file_to_modify [1]'
    file_with_mount = "#{mount}/#{file_without_mount}"
    file = file_info(file_without_mount, 2, 1)

    # mocking
    allow(File).to receive(:realpath).and_call_original
    allow(File).to receive(:realpath).with(mount).and_return(mount)
    allow(Dir).to receive(:glob).and_return([])
    allow(Dir).to receive(:glob).with("#{mount}/Peliculas/**/*").and_return([ file_with_mount ])
    allow(File).to receive(:file?).and_call_original
    allow(File).to receive(:file?).with(file_with_mount).and_return(true)
    allow(FileDisk).to receive(:find_using_filename_with_id).and_return(file)
    allow(FileDisk).to receive(:create_from_filename).with(file_with_mount, file_without_mount, 2).and_return(file)

    # testing
    hard_disk_files_info = TasksHelper::HardDiskFilesInfo.new(mount, 2)
    allow(hard_disk_files_info).to receive(:get_files_on_db).and_return({ file_without_mount => file})
    hard_disk_files_info.send(:process_info)
    expect(hard_disk_files_info.get_files_to_add.length).to eq(0)
    expect(hard_disk_files_info.get_files_to_remove.length).to eq(0)
    expect(hard_disk_files_info.get_files_to_update.length).to eq(0)
  end

  it "process_info should update an existing file because it's on DB, but has not the ID on name" do
    mount = 'mount'
    file_without_mount = 'Peliculas/file_to_modify'
    file_with_mount = "#{mount}/#{file_without_mount}"
    file_to_update = file_info(file_without_mount, 2, 1)
    expected_file_updated = file_info("#{file_without_mount} [1]", 2, 1)

    # mocking
    allow(File).to receive(:realpath).and_call_original
    allow(File).to receive(:realpath).with(mount).and_return(mount)
    allow(Dir).to receive(:glob).and_return([])
    allow(Dir).to receive(:glob).with("#{mount}/Peliculas/**/*").and_return([ file_with_mount ])
    allow(File).to receive(:file?).and_call_original
    allow(File).to receive(:file?).with(file_with_mount).and_return(true)
    allow(FileDisk).to receive(:find_using_filename_with_id).and_return(nil)
    allow(FileDisk).to receive(:create_from_filename).with(file_with_mount, file_without_mount, 2).and_return(file_to_update)

    # testing
    hard_disk_files_info = TasksHelper::HardDiskFilesInfo.new(mount, 2)
    allow(hard_disk_files_info).to receive(:get_files_on_db).and_return({ file_without_mount => file_to_update})
    hard_disk_files_info.send(:process_info)
    expect(hard_disk_files_info.get_files_to_add.length).to eq(0)
    expect(hard_disk_files_info.get_files_to_remove.length).to eq(0)
    expect(hard_disk_files_info.get_files_to_update.length).to eq(1)
    file_updated = hard_disk_files_info.get_files_to_update[0]
    expect(file_updated).to eq(expected_file_updated)
    expect(file_updated.original_name).to eq(file_without_mount)
  end

  it "process_info should remove a non-existing file" do
    mount = 'mount'
    file_without_mount = 'Peliculas/file_to_delete'
    file_with_mount = "#{mount}/#{file_without_mount}"
    file_to_remove = file_info(file_without_mount, 2, 1)

    # mocking
    allow(File).to receive(:realpath).and_call_original
    allow(File).to receive(:realpath).with(mount).and_return(mount)
    allow(Dir).to receive(:glob).and_return([])
    allow(File).to receive(:file?).and_call_original
    allow(FileDisk).to receive(:find_using_filename_with_id).and_return(nil)

    # testing
    hard_disk_files_info = TasksHelper::HardDiskFilesInfo.new(mount, 2)
    allow(hard_disk_files_info).to receive(:get_files_on_db).and_return({ file_without_mount => file_to_remove})
    hard_disk_files_info.send(:process_info)
    expect(hard_disk_files_info.get_files_to_add.length).to eq(0)
    expect(hard_disk_files_info.get_files_to_remove.length).to eq(1)
    expect(hard_disk_files_info.get_files_to_update.length).to eq(0)
    expect(hard_disk_files_info.get_files_to_remove[0]).to eq(file_to_remove)
  end

  # process
  it "process with no existing disk fails" do
    mount = 'mount'

    # mocking
    allow(File).to receive(:realpath).and_call_original
    allow(File).to receive(:realpath).with(mount).and_return(mount)
    allow(TasksHelper::HardDiskInfo).to receive(:read_from_mounted_disk).with(mount).and_return(disk_info(12345))

    # testing
    hard_disk_files_info = TasksHelper::HardDiskFilesInfo.new(mount, 12345)
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
    hard_disk_files_info = TasksHelper::HardDiskFilesInfo.new(mount, disk.id)
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
    hard_disk_files_info = TasksHelper::HardDiskFilesInfo.new(mount, disk.id)
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
    hard_disk_files_info = TasksHelper::HardDiskFilesInfo.new(mount, disk.id)
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
    hard_disk_files_info = TasksHelper::HardDiskFilesInfo.new(mount, disk.id)
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
    hard_disk_files_info = TasksHelper::HardDiskFilesInfo.new(mount, disk.id)
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
