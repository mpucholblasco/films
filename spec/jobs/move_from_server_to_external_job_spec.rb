require 'rails_helper'

RSpec.describe MoveFromServerToExternalJob, type: :job do
  it "get files with no elements returns empty list" do
    path = '/non-existent-path'
    allow(Dir).to receive(:glob).and_return([])
    allow(Dir).to receive(:glob).with(path).and_return([])

    real_files_to_move = MoveFromServerToExternalJob.obtain_files_to_move(path)
    expected_files_to_move = []
    expect(real_files_to_move).to eq(expected_files_to_move)
  end

  it "get max_progress_to_move when no elements returns 0" do
    real_max_progress_to_move = MoveFromServerToExternalJob.get_max_progress_to_move([])
    expected_max_progress_to_move = 0
    expect(real_max_progress_to_move).to eq(expected_max_progress_to_move)
  end

  it "get max_progress_to_move for several elements" do
    files = [ FakeFile.new(10), FakeFile.new(20) ]

    real_max_progress_to_move = MoveFromServerToExternalJob.get_max_progress_to_move(files)
    expected_max_progress_to_move = 10 + 20
    expect(real_max_progress_to_move).to eq(expected_max_progress_to_move)
  end

  it "process with no files does not raise errors" do
    source_path = '/non-existent-path'
    target_path = '/another-non-existent-path'
    allow(Dir).to receive(:glob).and_return([])
    allow(Dir).to receive(:glob).with(source_path).and_return([])

    MoveFromServerToExternalJob.process(source_path, target_path, DelayedJobProgress.new)
  end

  it "process with one file works" do
    source_path = '/non-existent-path'
    target_path = '/another-non-existent-path'
    allow(Dir).to receive(:glob).and_return([])
    allow(Dir).to receive(:glob).with(source_path).and_return([ FakeFile.new(10) ])

    MoveFromServerToExternalJob.process(source_path, target_path, DelayedJobProgress.new)
  end

  it "process with one file and full disk" do
    source_path = '/non-existent-path'
    target_path = '/another-non-existent-path'
    allow(Dir).to receive(:glob).and_return([])
    allow(Dir).to receive(:glob).with(source_path).and_return([ FakeFileFullDisk.new(10) ])
    allow(File).to receive(:unlink).with('/another-non-existent-path/basename').and_return(true)

    expect {
      MoveFromServerToExternalJob.process(source_path, target_path, DelayedJobProgress.new)
    }.to raise_error(StandardError)
  end

  private

  class FakeFile
    def initialize(blocks)
      @blocks = blocks
    end

    def rename(targetname)
      true
    end

    def basename
      'basename'
    end

    def blocks
      @blocks
    end

    def file?
      true
    end
  end

  class FakeFileFullDisk < FakeFile
    def rename(targetname)
      raise IOError.new('full disk')
    end
  end
end
