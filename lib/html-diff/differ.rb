require 'nokogiri'
require 'digest'
require 'pqueue'

module HTMLDiff
  class Differ
    def diff_strings(left, right)
      diff parse(left).root, parse(right).root
    end

    def diff_fragments(left, right)
      diff parse_fragments(left).child, parse_fragments(right).child
    end

    def diff(ldoc, rdoc)
      reset

      match_by_ids ldoc, rdoc
      prep_with @lsignatures, ldoc
      prep_with @rsignatures, rdoc

      perform_initial_top_down_matching [ldoc], [rdoc]

      @matchqueue.push(rdoc)
      perform_initial_matching

      match_bottom_up ldoc
      match_top_down  ldoc

      DeltaTreeBuilder.new(ldoc, rdoc, @weights, @forward, @backward).build
    end

    private

    def parse(string)
      Nokogiri::HTML(string, nil, nil, (Nokogiri::XML::ParseOptions::DEFAULT_HTML & Nokogiri::XML::ParseOptions::NOBLANKS))
    end

    def parse_fragments(string)
      Nokogiri::HTML::DocumentFragment.parse(string)
    end

    def reset
      @forward     = {}
      @backward    = {}
      @weights     = {}
      @depths      = {}
      @lsignatures = {}
      @rsignatures = {}
      @matchqueue  = PQueue.new() { |a, b| @weights[a] > @weights[b] }
    end

    def match_by_ids(ldoc, rdoc)
      rightside = rdoc.css("[id]").to_a
      ldoc.css("[id]").each do |element|
        rindex = rightside.find_index { |e| e[:id] == element[:id] }
        if rindex
          record_matching element, rightside[rindex]
          rightside.delete_at(rindex)
        end
      end
    end

    def prep_with(sig_hash, element, level=0)
      weights    = weight_for(element)
      signatures = [signature_part_for(element)]
      element.children.each do |child|
        weight, signature = prep_with(sig_hash, child, level+1)
        weights += weight
        signatures << signature
      end

      @weights[element] = weights
      sig_hash[element] = hash_for(signatures)
      @depths[element]  = level

      [ @weights[element], sig_hash[element] ]
    end

    def weight_for(element)
      if element.text? or element.cdata?
        1 + Math.log(element.text.size)
      else
        1
      end
    end

    def signature_part_for(element)
      if element.text? or element.cdata?
        element.text
      else
        element.name
      end
    end

    def hash_for(array)
      Digest::SHA256.digest array.join(";")
    end

    def record_matching(left, right)
      @forward[left]   = right
      @backward[right] = left
    end

    def perform_initial_top_down_matching(lnodes, rnodes)
      _lnodes = lnodes.reject(&:text?)
      _rnodes = rnodes.reject(&:text?)

      _lnodes.each do |lnode|
        lcounts    = _lnodes.count  { |c| c.name == lnode.name }
        candidates = _rnodes.select { |c| c.name == lnode.name }
        if lcounts == 1 && candidates.size == 1
          record_matching lnode, candidates.first
          perform_initial_top_down_matching lnode.children, candidates.first.children
        end
      end
    end

    def perform_initial_matching
      while @matchqueue.size > 0
        element = @matchqueue.pop
        if @backward[element].nil? && (match = find_best_match(element))
          match_all_children match, element
          match_parents match, element
        else
          element.children.each { |c| @matchqueue.push c }
        end
      end
    end

    def find_best_match(element)
      candidates = []
      @lsignatures.each do |left, sig|
        if @forward[left].nil? && sig == @rsignatures[element]
          candidates << left
        end
      end

      if candidates.size == 0
        return
      elsif candidates.size == 1
        return candidates.first
      else
        matching_parents = candidates.select do |left|
          @forward[left.parent] == element.parent
        end

        if matching_parents.size == 1
          return matching_parents.first
        else
          return
        end
      end
    end

    def match_all_children(left, right)
      record_matching left, right
      left.children.zip(right.children).each do |a, b|
        match_all_children a, b
      end
    end

    def match_parents(left, right)
      # TODO implement multi-ancestor matching
      return if @forward[left.parent] || @backward[right.parent]
      if left.parent.name == right.parent.name
        record_matching left, right
      end
    end

    def match_bottom_up(element)
      element.children.each do |child|
        match_bottom_up child
      end

      if element.respond_to?(:parent) && @forward[element.parent]
        match = @forward[element.parent].children.find { |c| @backward[c].nil? && c.name == element.name }
        record_matching(element, match) if match
      end
    end

    def match_top_down(element)
      if @forward[element].nil?
        childmatches = element.children.map { |c| @forward[c] && @forward[c].parent }.compact.uniq
        childmatches.reject! { |e| @backward[e] }
        if childmatches.size == 1 && childmatches.first.name == element.name
          record_matching(element, childmatches.first)
        end
      end

      element.children.each do |child|
        match_top_down child
      end
    end
  end
end
