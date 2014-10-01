require "spec_helper"

RSpec.describe StoreAgent::Node::Object do
  let :user do
    StoreAgent::User.new("foo", "bar")
  end
  let :workspace do
    user.workspace("bar")
  end

  context "初期化のテスト" do
    it "Workspace が無い Object は作成できない" do
      expect do
        StoreAgent::Node::Object.new(path: "/")
      end.to raise_error
    end
  end

  context "初期化時に path の先頭の . や / を / に変換する" do
    let :object do
      StoreAgent::Node::Object.new(workspace: workspace, path: @path)
    end

    it "先頭に / が無ければ追加する" do
      @path = "foo"
      expect(object.path).to eq "/foo"
    end
    it ". は / に変換される" do
      @path = "."
      expect(object.path).to eq "/"
    end
    it "/// は / に変換される" do
      @path = "///"
      expect(object.path).to eq "/"
    end
    it "/././. は / に変換される" do
      @path = "/././."
      expect(object.path).to eq "/"
    end
    it "../.. は / に変換される" do
      @path = "../.."
      expect(object.path).to eq "/"
    end
    it "../foo/bar は /foo/bar に変換される" do
      @path = "../foo/bar"
      expect(object.path).to eq "/foo/bar"
    end
  end

  context "オブジェクト作成" do
    it "StoreAgent::Node::Object クラスそのままでは作成できない" do
      expect do
        StoreAgent::Node::Object.new(workspace: workspace, path: "/hoge.txt").create
      end.to raise_error
    end
  end
end
