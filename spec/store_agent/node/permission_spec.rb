require "spec_helper"

RSpec.describe StoreAgent::Node::Permission do
  let :super_user do
    StoreAgent::Superuser.new
  end
  let :owner do
    StoreAgent::User.new("owner_uid")
  end
  let :user do
    StoreAgent::User.new("user_id")
  end
  let :group_user do
    StoreAgent::User.new("owner_uid", "group")
  end
  let :namespaced_user do
    StoreAgent::User.new(["user_id", "namespaced_id"])
  end
  let :guest do
    StoreAgent::Guest.new
  end
  let :workspace do
    owner.workspace(workspace_name)
  end

  context "パーミッションのテスト" do
    let :workspace_name do
      "permission_workspace"
    end
    before do
      if !workspace.exists?
        workspace.create
        owner.workspace(workspace_name).directory("foo").create
        owner.workspace(workspace_name).file("foo/bar.txt").create("body" => "1234567890")
        owner.workspace(workspace_name).file("foo/hoge.txt").create("body" => "0987654321")
      end
      @root_node = workspace.directory("/")
    end

    context "Workspace 作成直後のパーミッション" do
      it "Superuser には全権限がある" do
        node = super_user.workspace(workspace_name).directory("/")
        expect(node.permission.allow?("read")).to be true
        expect(node.permission.allow?("write")).to be true
      end
      it "Workspace の作成者には全権限がある" do
        expect(@root_node.permission.allow?("read")).to be true
        expect(@root_node.permission.allow?("write")).to be true
      end
      it "ID に Workspace の作成者の ID を含む場合、権限がある" do
        node = group_user.workspace(workspace_name).root
        expect(node.permission.allow?("read")).to be true
        expect(node.permission.allow?("write")).to be true
      end
      it "ゲスト User には全権限が無い" do
        node = guest.workspace(workspace_name).directory("/")
        expect(node.permission.allow?("read")).to be false
        expect(node.permission.allow?("write")).to be false
      end
    end
    context "ID が配列のユーザーで Workspace を作成する" do
      before do
        @namespaced_workspace = namespaced_user.workspace("permission_workspace_namespaced_id")
        if !@namespaced_workspace.exists?
          @namespaced_workspace.create
        end
        @root_node = @namespaced_workspace.root
      end

      it "権限情報はネストしたハッシュになる" do
        expect(@root_node.permission.data["users"]["user_id"]["namespaced_id"]["read"]).to eq true
        expect(@root_node.permission.data["users"]["user_id"]["namespaced_id"]["write"]).to eq true
      end
      it "Superuser には権限がある" do
        node = super_user.workspace("permission_workspace_namespaced_id").directory("/")
        expect(node.permission.allow?("read")).to be true
        expect(node.permission.allow?("write")).to be true
      end
      it "Workspace の作成者には権限がある" do
        expect(@root_node.permission.allow?("read")).to be true
        expect(@root_node.permission.allow?("write")).to be true
      end
      it "User には権限が無い" do
        node = user.workspace("permission_workspace_namespaced_id").directory("/")
        expect(node.permission.allow?("read")).to be false
        expect(node.permission.allow?("write")).to be false
      end
    end

    context "パーミッションの変更" do
      before do
        dir = owner.workspace(workspace_name).directory("bar")
        if !dir.exists?
          dir.create
          owner.workspace(workspace_name).file("bar/hoge.txt").create("body" => "1234567890")
        end
      end

      it "ファイルの権限を変更する" do
        owner.workspace(workspace_name).file("bar/hoge.txt").set_permission(identifier: "user_id", permission_values: {"read" => true})
        expect(user.workspace(workspace_name).file("bar/hoge.txt").permission.allow?("read")).to be true
        owner.workspace(workspace_name).file("bar/hoge.txt").set_permission(identifier: "user_id", permission_values: {"read" => false})
        expect(user.workspace(workspace_name).file("bar/hoge.txt").permission.allow?("read")).to be false
        owner.workspace(workspace_name).file("bar/hoge.txt").set_permission(identifier: "user_id", permission_values: {"read" => true})
        owner.workspace(workspace_name).file("bar/hoge.txt").unset_permission(identifier: "user_id", permission_names: "read")
        expect(user.workspace(workspace_name).file("bar/hoge.txt").permission.allow?("read")).to be false
      end
      it "ディレクトリの単独の権限を変更した場合、配下ファイルの権限は変わらない" do
        owner.workspace(workspace_name).directory("bar").set_permission(identifier: "user_id", permission_values: {"write" => true})
        expect(user.workspace(workspace_name).file("bar/hoge.txt").permission.allow?("write")).to be false
        owner.workspace(workspace_name).directory("bar").set_permission(identifier: "user_id", permission_values: {"write" => false})
        expect(user.workspace(workspace_name).file("bar/hoge.txt").permission.allow?("write")).to be false
        owner.workspace(workspace_name).directory("bar").set_permission(identifier: "user_id", permission_values: {"write" => true}, recursive: true)
        owner.workspace(workspace_name).directory("bar").unset_permission(identifier: "user_id", permission_names: "write")
        expect(user.workspace(workspace_name).file("bar/hoge.txt").permission.allow?("write")).to be true
      end
      it "サブツリー全体の権限を変更した場合、配下ファイルの権限も変更される" do
        owner.workspace(workspace_name).directory("bar").set_permission(identifier: "user_id", permission_values: {"execute" => true}, recursive: true)
        expect(user.workspace(workspace_name).file("bar/hoge.txt").permission.allow?("execute")).to be true
        owner.workspace(workspace_name).directory("bar").set_permission(identifier: "user_id", permission_values: {"execute" => false}, recursive: true)
        expect(user.workspace(workspace_name).file("bar/hoge.txt").permission.allow?("execute")).to be false
        owner.workspace(workspace_name).directory("bar").set_permission(identifier: "user_id", permission_values: {"execute" => true}, recursive: true)
        owner.workspace(workspace_name).directory("bar").unset_permission(identifier: "user_id", permission_names: "execute", recursive: true)
        expect(user.workspace(workspace_name).file("bar/hoge.txt").permission.allow?("execute")).to be false
      end
    end

    context "Superuser" do
      it "ディレクトリを作成できる" do
        expect(super_user.workspace(workspace_name).directory("foo/super_user_dir").create)
      end
      it "ファイルを読める" do
        expect(super_user.workspace(workspace_name).file("foo/bar.txt").read).to eq "1234567890"
      end
      it "ファイルを作成できる" do
        expect(super_user.workspace(workspace_name).file("foo/super_user.txt").create("body" => ""))
      end
    end
    context "Owner" do
      it "ディレクトリを作成できる" do
        expect(owner.workspace(workspace_name).directory("foo/owner_dir").create)
      end
      it "ファイルを読める" do
        expect(owner.workspace(workspace_name).file("foo/bar.txt").read).to eq "1234567890"
      end
      it "ファイルを作成できる" do
        expect(owner.workspace(workspace_name).file("foo/owner.txt").create("body" => ""))
      end
    end
    context "User" do
      it "ディレクトリを作成できない" do
        expect do
          user.workspace(workspace_name).directory("foo/user_dir").create
        end.to raise_error
      end
      it "ファイルを読めない" do
        expect do
          user.workspace(workspace_name).file("foo/bar.txt").read
        end.to raise_error
      end
      it "ファイルを作成できない" do
        expect do
          user.workspace(workspace_name).file("foo/user.txt").create("body" => "")
        end.to raise_error
      end
      it "権限を付与されればファイルを読めるようになる" do
        owner.workspace(workspace_name).file("foo/hoge.txt").set_permission(identifier: "user_id", permission_values: {"read" => true})
        expect(user.workspace(workspace_name).file("foo/hoge.txt").read).to eq "0987654321"
      end
    end
    context "User(namespaced)" do
      it "ディレクトリを作成できない" do
        expect do
          namespaced_user.workspace(workspace_name).directory("foo/namespaced_user_dir").create
        end.to raise_error
      end
    end
    context "Guest" do
      it "ディレクトリを作成できない" do
        expect do
          guest.workspace(workspace_name).directory("foo/guest_dir").create
        end.to raise_error
      end
      it "ファイルを読めない" do
        expect do
          guest.workspace(workspace_name).file("foo/bar.txt").read
        end.to raise_error
      end
      it "ファイルを作成できない" do
        expect do
          guest.workspace(workspace_name).file("foo/guest.txt").create("body" => "")
        end.to raise_error
      end
    end
  end
end
