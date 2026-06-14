require "net/http"
require "json"

class GistPublisher
  def initialize(token: nil)
    @token = token
  end

  def create_gist(description:, content: nil, links: nil)
    if links
      content = links.map { |link| "- [#{link.title}](#{link.url})" }.join("\n")
    end
    uri = URI("https://api.github.com/gists")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "token #{@token}"
    request.body = {
      description: description,
      public: false,
      files: {
        "Necessary Eval: Links!" => { content: content }
      }
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    JSON.parse(response.body, symbolize_names: true)
  end

  def update_gist(id:, content:)
    uri = URI("https://api.github.com/gists/#{id}")
    request = Net::HTTP::Patch.new(uri)
    request["Authorization"] = "token #{@token}"
    request.body = {
      files: {
        "Necessary Eval: Links!" => { content: content }
      }
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    response.is_a?(Net::HTTPOK)
  end
end
