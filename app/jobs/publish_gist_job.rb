class PublishGistJob < ApplicationJob
  queue_as :default

  def perform(link_id:, session_id:)
    link = Link.find(link_id)
    publisher = GistPublisher.new(token: Rails.application.credentials.github.token)
    result = publisher.create_gist(description: link.title, content: link.url)
    link.update!(gist_id: result[:id])
    publisher.update_gist(id: result[:id], content: link.url)

    link.broadcast_replace_to [ link, session_id ], partial: "links/link", locals: { session_id: session_id }
  end
end
