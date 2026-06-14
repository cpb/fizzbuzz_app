class ApplicationTestCase < ActiveSupport::TestCase
  class_attribute :cassette_prefix

  def self.inherited(subclass)
    super
    return unless (name = subclass.name)
    file, = subclass.module_parent.const_source_location(name.demodulize)
    return unless file
    relative = Pathname.new(file).relative_path_from(Rails.root).to_s
    parts = relative.split("/")
    test_idx = parts.rindex("test")
    return unless test_idx
    subclass.cassette_prefix = "#{parts[0..test_idx].join("/")}/cassettes"
  end

  def use_cassette(name, **opts, &block)
    VCR.use_cassette("#{self.class.cassette_prefix}/#{name}", **opts, &block)
  end
end
