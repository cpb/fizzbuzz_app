class PublishGistJob < ApplicationJob
  queue_as :default

  def perform(link_id:)
    link = Link.find(link_id)
    publisher = GistPublisher.new(token: ENV["GITHUB_TOKEN"])
    result = publisher.create_gist(description: link.title, content: link.url)
    link.update!(gist_id: result[:id])
    publisher.update_gist(id: result[:id], content: link.url)
  end
end
