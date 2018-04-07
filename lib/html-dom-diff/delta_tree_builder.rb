module HTMLDOMDiff
  class DeltaTreeBuilder
    attr_reader :ldoc, :rdoc
    def initialize(ldoc, rdoc)
      @ldoc     = ldoc
      @rdoc     = rdoc
      @weights  = {}
      @forward  = {}
      @backward = {}
    end

    def build
      wrap @rdoc
    end

    def add_weight(element, weight)
      @weights[element] = weight
    end

    def weight(element)
      @weights[element]
    end

    def match(left, right)
      @forward[left]   = right
      @backward[right] = left
    end

    def left_matches?(lnode, rnode)
      @forward[lnode] == rnode
    end

    def left_match(lnode)
      @forward[lnode]
    end

    def left_matched?(lnode)
      @forward.has_key?(lnode)
    end

    def right_matched?(rnode)
      @backward.has_key?(rnode)
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
