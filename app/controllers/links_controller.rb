class LinksController < ApplicationController
  def publish
    link = Link.find(params[:id])
    PublishGistJob.perform_later(link_id: link.id)
    redirect_to root_url, notice: "Publishing job enqueued."
  end
end
