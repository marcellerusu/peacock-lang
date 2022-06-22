class AssertionError < RuntimeError
end

class NotImplemented < AssertionError
end

def assert(&block)
  raise AssertionError unless yield
end

def assert_not_reached!
  raise AssertionError
end

def not_implemented!(&block)
  if block
    block.call
  end
  raise NotImplemented
end
