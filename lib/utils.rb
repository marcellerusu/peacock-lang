class AssertionError < RuntimeError
end

class NotImplemented < AssertionError
end

# TODO: later we could use Context to store the
# entire ast parents here
# & use this to search local scopes
# not have to rely on __try(() => eval('var_name')) || this.var_name())
# we could just know if its in scope, or if its a method of parent class..

class Context
  attr_reader :value

  def initialize(contexts = [], value = nil)
    @contexts = contexts
    @value = value
  end

  def push!(context)
    @contexts.push context
    self
  end

  def set_value!(value)
    @value = value
  end

  def set_value(value)
    Context.new @contexts, value
  end

  def push(context)
    clone.push! context
  end

  def empty?
    @contexts.size == 0
  end

  def clone
    Context.new @contexts.clone
  end

  def pop!(context)
    assert { @contexts.last == context }
    @contexts.pop
  end

  def directly_in_a?(context)
    @contexts.last == context
  end

  def in_a?(context)
    @contexts.any? { |c| c == context }
  end
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
