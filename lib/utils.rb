class AssertionError < RuntimeError
end

def assert(&block)
  raise AssertionError unless yield
end
