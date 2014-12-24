class FileController < ApplicationController
  def index
    @files = FileDisk.search(params[:search], params[:page])
  end
end
