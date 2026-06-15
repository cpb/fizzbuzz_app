module EvalRegistry
  @fixture_dirs = []

  def self.register(dir)
    @fixture_dirs << Rails.root.join(dir)
  end

  def self.fixture_dirs
    @fixture_dirs.dup
  end
end
