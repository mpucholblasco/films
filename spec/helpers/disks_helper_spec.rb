require 'rails_helper'

RSpec.describe DisksHelper, type: :helper do
  # process_info
  it "process_info should add a new file if DB is empty and file does not contain ID" do
    mount = 'mount'
    file_without_mount = 'Peliculas/file_to_add'
    file_with_mount = "#{mount}/#{file_without_mount}"
    file_to_add = file_info(file_without_mount)

    # mocking
    allow(FileDisk).to receive(:find_using_filename_with_id).and_return(nil)
    allow(FileDisk).to receive(:create_from_filename).with(file_with_mount, file_without_mount, 1).and_return(file_to_add)

    # testing
    hard_disk_files_info = DisksHelper::HardDiskFilesUpdaterInfo.new(mount, 1)
    allow(hard_disk_files_info).to receive(:get_files_on_db).and_return({})
    hard_disk_files_info.add_file(file_with_mount)
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
    allow(FileDisk).to receive(:find_using_filename_with_id).and_return(nil)
    allow(FileDisk).to receive(:create_from_filename).with(file_with_mount, file_without_mount, 1).and_return(file_to_add)

    # testing
    hard_disk_files_info = DisksHelper::HardDiskFilesUpdaterInfo.new(mount, 1)
    allow(hard_disk_files_info).to receive(:get_files_on_db).and_return({})
    hard_disk_files_info.add_file(file_with_mount)
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
    allow(FileDisk).to receive(:find_using_filename_with_id).and_return(file_info(file_without_mount, 1))
    allow(FileDisk).to receive(:create_from_filename).with(file_with_mount, file_without_mount, 2).and_return(file_to_update)

    # testing
    hard_disk_files_info = DisksHelper::HardDiskFilesUpdaterInfo.new(mount, 2)
    allow(hard_disk_files_info).to receive(:get_files_on_db).and_return({})
    hard_disk_files_info.add_file(file_with_mount)
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
    allow(FileDisk).to receive(:find_using_filename_with_id).and_return(file_on_db)
    allow(FileDisk).to receive(:create_from_filename).with(file_with_mount, file_without_mount, 2).and_return(file_to_update)

    # testing
    hard_disk_files_info = DisksHelper::HardDiskFilesUpdaterInfo.new(mount, 2)
    allow(hard_disk_files_info).to receive(:get_files_on_db).and_return({ file_on_db_filename => file_on_db})
    hard_disk_files_info.add_file(file_with_mount)
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
    allow(FileDisk).to receive(:find_using_filename_with_id).and_return(file)
    allow(FileDisk).to receive(:create_from_filename).with(file_with_mount, file_without_mount, 2).and_return(file)

    # testing
    hard_disk_files_info = DisksHelper::HardDiskFilesUpdaterInfo.new(mount, 2)
    allow(hard_disk_files_info).to receive(:get_files_on_db).and_return({ file_without_mount => file})
    hard_disk_files_info.add_file(file_with_mount)
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
    allow(FileDisk).to receive(:find_using_filename_with_id).and_return(nil)
    allow(FileDisk).to receive(:create_from_filename).with(file_with_mount, file_without_mount, 2).and_return(file_to_update)

    # testing
    hard_disk_files_info = DisksHelper::HardDiskFilesUpdaterInfo.new(mount, 2)
    allow(hard_disk_files_info).to receive(:get_files_on_db).and_return({ file_without_mount => file_to_update})
    hard_disk_files_info.add_file(file_with_mount)
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
    allow(FileDisk).to receive(:find_using_filename_with_id).and_return(nil)

    # testing
    hard_disk_files_info = DisksHelper::HardDiskFilesUpdaterInfo.new(mount, 2)
    allow(hard_disk_files_info).to receive(:get_files_on_db).and_return({ file_without_mount => file_to_remove})
    expect(hard_disk_files_info.get_files_to_add.length).to eq(0)
    expect(hard_disk_files_info.get_files_to_remove.length).to eq(1)
    expect(hard_disk_files_info.get_files_to_update.length).to eq(0)
    expect(hard_disk_files_info.get_files_to_remove[0]).to eq(file_to_remove)
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
    result = TasksHelper::HardDiskInfo.new
    result.name = 'disk'
    result.id = 2
    result.total_size = 100
    result.free_size = 100
    result
  end
end
