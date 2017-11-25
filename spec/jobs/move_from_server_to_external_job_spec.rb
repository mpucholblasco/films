require 'rails_helper'

RSpec.describe MoveFromServerToExternalJob, type: :job do
  it "get files with no elements returns empty list" do
    path = '/non-existent-path'
    allow(Dir).to receive(:glob).and_return([])
    allow(Dir).to receive(:glob).with(File.join(path, '*')).and_return([])

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
    files = [ '/non-existing-1', '/non-existing-2' ]
    blocks = [ 10, 20 ]
    files.each_with_index { |file,index|
      allow(File).to receive(:stat).with(file).and_return(FakeFileStat.new(blocks[index]))
    }

    real_max_progress_to_move = MoveFromServerToExternalJob.get_max_progress_to_move(files)
    expected_max_progress_to_move = 10 + 20
    expect(real_max_progress_to_move).to eq(expected_max_progress_to_move)
  end

  it "process with no files does not raise errors" do
    source_path = '/non-existent-path'
    target_path = '/another-non-existent-path'
    allow(Dir).to receive(:glob).and_return([])
    allow(Dir).to receive(:glob).with(File.join(source_path, '*')).and_return([])
    allow(File).to receive(:directory?).with(target_path).and_return(true)

    MoveFromServerToExternalJob.process(source_path, target_path, DelayedJobProgress.new)
  end

  it "process with one file works" do
    source_path = '/non-existent-path'
    source_filename = "#{source_path}/non-existing-file"
    target_path = '/another-non-existent-path'
    target_filename = "#{target_path}/non-existing-file"
    allow(Dir).to receive(:glob).and_return([])
    allow(Dir).to receive(:glob).with(File.join(source_path, '*')).and_return([ source_filename ])
    allow(File).to receive(:directory?).with(target_path).and_return(true)
    allow(File).to receive(:file?).with(source_filename).and_return(true)
    allow(File).to receive(:stat).with(source_filename).and_return(FakeFileStat.new(10))
    allow(FileUtils).to receive(:mv).with(source_filename, target_filename).and_return(0)

    MoveFromServerToExternalJob.process(source_path, target_path, DelayedJobProgress.new)
  end

  it "process with one file and full disk" do
    source_path = '/non-existent-path'
    source_filename = "#{source_path}/non-existing-file"
    target_path = '/another-non-existent-path'
    target_filename = "#{target_path}/non-existing-file"
    allow(Dir).to receive(:glob).and_return([])
    allow(Dir).to receive(:glob).with(File.join(source_path, '*')).and_return([ source_filename ])
    allow(File).to receive(:directory?).with(target_path).and_return(true)
    allow(File).to receive(:file?).with(source_filename).and_return(true)
    allow(File).to receive(:stat).with(source_filename).and_return(FakeFileStat.new(10))
    allow(FileUtils).to receive(:mv).with(source_filename, target_filename).and_raise(IOError.new('Full disk'))
    allow(File).to receive(:unlink).with(target_filename).and_return(true)

    expect {
      MoveFromServerToExternalJob.process(source_path, target_path, DelayedJobProgress.new)
    }.to raise_error(StandardError)
  end

  private

  class FakeFileStat
    def initialize(blocks)
      @blocks = blocks
    end

    def blocks
      @blocks
    end
  end
end
