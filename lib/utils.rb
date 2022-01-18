class AssertionError < RuntimeError
end

def assert(&block)
  raise AssertionError unless yield
end

def assert_not_reached
  raise AssertionError
end
