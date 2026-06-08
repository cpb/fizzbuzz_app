class LinksController < ApplicationController
  def index
    @links = Link.all
  end

  def new
    @link = Link.new
  end

  def create
    @link = Link.new(params.require(:link).permit(:title, :url))
    if @link.save
      redirect_to links_path, notice: "Link was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def publish
    PublishGistJob.perform_later({})
    head :no_content
  end
end
