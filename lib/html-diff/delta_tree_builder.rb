module HTMLDiff
  class DeltaTreeBuilder
    attr_reader :ldoc, :rdoc
    def initialize(ldoc, rdoc, weights, forward, backward)
      @ldoc     = ldoc
      @rdoc     = rdoc
      @weights  = weights
      @forward  = forward
      @backward = backward
    end

    def build
      wrap @rdoc
    end

    private

    def wrap(rnode, parent=nil)
      result = Node.new rnode, @backward[rnode], parent
      rnode.children.each do |child|
        wrap child, result
      end
      if parent
        parent.add_child result
      end
      if @backward[rnode]
        @backward[rnode].children.each do |child|
          reverse_wrap(child, result)
        end
      end
      result
    end

    def reverse_wrap(lnode, parent)
      return if @forward[lnode]
      result = Node.new nil, lnode
      lnode.children.each { |c| reverse_wrap c, result }
      parent.add_child result
    end
  end
end
