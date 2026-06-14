class PublishGistJob < ApplicationJob
  queue_as :default

  def perform(link_id: nil, session_id: nil)
    token = Rails.application.credentials.dig(:github, :token)
    publisher = GistPublisher.new(token: token)

    if link_id
      link = Link.find(link_id)
      result = publisher.create_gist(description: link.title, content: link.url)
      link.update!(gist_id: result[:id])
      publisher.update_gist(id: result[:id], content: link.url)
      link.broadcast_replace_to [ link, session_id ], partial: "links/link", locals: { session_id: session_id }
    else
      result = publisher.create_gist(description: "Links", links: Link.all)
      gist = Gist.create!(url: result[:html_url], published_at: Time.current)
      Turbo::StreamsChannel.broadcast_append_to(
        :links,
        target: "qr_code_container",
        partial: "links/qr_code",
        locals: { gist: gist }
      )
    end
  end
end
