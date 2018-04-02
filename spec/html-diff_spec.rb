RSpec.describe HTMLDiff::Differ do
  def diff_strings(left, right)
    described_class.new.diff_strings(left, right)
  end

  describe "node-level changes" do
    it "attribute differences" do
      '<link href="style-b9ce72f6a052368bd1e7abe3c8ab3c71.css" />'
      '<link href="style-cec3d286143ba5059503534a7bb5147c.css" />'
    end

    it "attribute insertion" do
      '<link href="style.css" />'
      '<link href="style.css" rel="stylesheet" />'
    end

    it "attribute removal" do
      '<link href="style.css" rel="stylesheet" />'
      '<link href="style.css" />'
    end

    it "text differences" do
      '<h1>Title A</h1>'
      '<h1>Some other title</h1>'
    end

    it "tagname differences" do
      '<h1>Title A</h1>'
      '<h2>Title A</h2>'
    end
  end

  describe "tree-level changes" do
    it "node insertion" do
      '<h1>Title A</h1>'
      '<div><h1>Title A</h1><div>'
    end

    it "node removal" do
      '<div><h1>Title A</h1><div>'
      '<h1>Title A</h1>'
    end

    it "subtree insertion" do
      '<h1>Title A</h1>'
      '<h1>Title A</h1><p>some text</p>'
    end

    it "subtree removal" do
      '<h1>Title A</h1><p>some text</p>'
      '<h1>Title A</h1>'
    end

    it "subtree move" do
      '<div></div><div><h1>Title A</h1></div>'
      '<div><h1>Title A</h1></div><div></div>'
    end
  end
end
