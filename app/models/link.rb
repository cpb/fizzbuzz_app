class Link
  include ActiveModel::Validations
  attr_accessor :title, :url

  def initialize(attrs = {})
    attrs.each { |k, v| public_send(:"#{k}=", v) }
  end
end
