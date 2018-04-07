module HTMLDiff
  class Node
    attr_reader :parent, :children

    attr_reader :rnode

    def initialize(rnode, lnode, parent=nil)
      @rnode    = rnode
      @lnode    = lnode
      @parent   = parent
      @children = []
    end

    def add_child(child)
      @children << child
    end

    def self_and_all_children
      [self] + @children.map(&:self_and_all_children).flatten
    end

    # attributes
    def attributes
      @rnode.attributes
    end

    def original_attributes
      @lnode.attributes
    end

    def changed_attribute_names
      result = []
      attributes.each do |k, v|
        result << k if original_attributes[k].nil? || (v.value != original_attributes[k].value)
      end
      original_attributes.each do |k, v|
        result << k if attributes[k].nil? || (v.value != attributes[k].value)
      end
      result.uniq
    end

    def text
      @rnode.text
    end

    def original_text
      @lnode&.text
    end

    def name
      if @rnode
        @rnode.name
      else
        @lnode.name
      end
    end

    def to_html
      @rnode.to_html
    end

    def as_tree_string(level=0)
      result  = [(" "*level) + "#{name} - :#{state}"]
      result += children.map { |c| c.as_tree_string(level+1) }
      result.join("\n")
    end

    # states
    def changed?
      if @rnode.text?
        text != original_text
      else
        attributes_changed?
      end
    end

    def state
      [:moved, :inserted, :removed, :matched].each do |_state|
        return _state if send("#{_state}?")
      end
    end

    def matched?
      ! (inserted? || removed? || moved?)
    end

    def inserted?
      @lnode.nil?
    end

    def removed?
      @rnode.nil?
    end

    def moved?
      return false if inserted? || removed? || @parent.nil?
      !@parent.parent_of? @lnode, @rnode
    end

    protected

    def attributes_changed?
      return true if attributes.size != original_attributes.size
      attributes.each do |k, v|
        if v != original_attributes[k]
          return true
        end
      end
      false
    end

    def parent_of?(lchild, rchild)
      return false if @lnode.nil? || @rnode.nil?
      return false unless @lnode.children.include?(lchild)
      @rnode.children.include?(rchild)
    end
  end
end
