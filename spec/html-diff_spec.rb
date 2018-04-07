RSpec.describe HTMLDiff::Differ do
  def diff_strings(left, right)
    described_class.new.diff_strings(left, right)
  end

  def diff_fragments(left, right)
    described_class.new.diff_fragments(left, right)
  end

  describe "node-level changes" do
    it "attribute differences" do
      node = diff_fragments '<link href="style-b9ce72f6a052368bd1e7abe3c8ab3c71.css" />', '<link href="style-cec3d286143ba5059503534a7bb5147c.css" />'
      expect(node.children.size).to eq 0
      expect(node).to be_changed
      expect(node.changed_attribute_names).to eq ['href']
      expect(node.attributes['href'].value).to eq "style-cec3d286143ba5059503534a7bb5147c.css"
      expect(node.original_attributes['href'].value).to eq "style-b9ce72f6a052368bd1e7abe3c8ab3c71.css"
    end

    it "attribute insertion" do
      tree = diff_fragments '<link href="style.css" />', '<link href="style.css" rel="stylesheet" />'
      expect(tree.children.size).to eq 0
      expect(tree).to be_changed
      expect(tree.changed_attribute_names).to eq ['rel']
      expect(tree.attributes['rel'].value).to eq "stylesheet"
      expect(tree.original_attributes['rel']).to be_nil
    end

    it "attribute removal" do
      tree = diff_fragments '<link href="style.css" rel="stylesheet" />', '<link href="style.css" />'
      expect(tree.children.size).to eq 0
      expect(tree).to be_changed
      expect(tree.changed_attribute_names).to eq ['rel']
      expect(tree.attributes['rel']).to be_nil
      expect(tree.original_attributes['rel'].value).to eq "stylesheet"
    end

    it "text differences" do
      node = diff_fragments '<h1>Title A</h1>', '<h1>Some other title</h1>'
      expect(node.children.size).to eq 1
      expect(node).to be_matched
      expect(node.text).to eq "Some other title"
      expect(node.original_text).to eq "Title A"
    end

    it "tagname differences" do
      node = diff_fragments '<h1>Title A</h1>', '<h2>Title A</h2>'
      expect(node.children.size).to eq 1
      expect(node).to be_inserted
      expect(node.name).to eq "h2"
    end
  end

  describe "tree-level changes" do
    it "node insertion" do
      node = diff_fragments '<h1>Title A</h1>', '<div><h1>Title A</h1></div>'
      expect(node).to be_inserted
      expect(node.children.size).to eq 1
      expect(node.children.first).to be_moved
      expect(node.children.first.text).to eq "Title A"
    end

    it "node removal" do
      node = diff_fragments '<body><div><h1>Title A</h1></div></body>', '<body><h1>Title A</h1></body>'
      expect(node).to be_matched
      expect(node.children.size).to eq 2
      expect(node.children.first).to be_moved
      expect(node.children.first.text).to eq "Title A"
      expect(node.children.last).to be_removed
    end

    it "subtree insertion" do
      node = diff_fragments '<body><div><h1>Title A</h1></div></body>', '<body><div><h1>Title A</h1><p>some text <a href="#">here</a></p></div></body>'
      expect(node.children.first).to be_matched
      expect(node.children.first.children.last.self_and_all_children.size).to eq 4
      expect(node.children.first.children.last.self_and_all_children).to all(be_inserted)
    end

    it "subtree removal" do
      node = diff_fragments '<body><h1>Title A</h1><p>some text <a href="#">here</a></p></body>', '<body><h1>Title A</h1></body>'
      expect(node).to be_matched
      expect(node.children.first).to be_matched
      expect(node.children.last.self_and_all_children.size).to eq 4
      expect(node.children.last.self_and_all_children).to all(be_removed)
    end

    it "subtree move" do
      node = diff_fragments '<body><nav></nav><div><h1>Title A</h1></div></body>', '<body><nav><h1>Title A</h1></nav><div></div></body>'
      expect(node).to be_matched
      expect(node.children.first).to be_matched
      expect(node.children.first.children.first).to be_moved
    end
  end
end
