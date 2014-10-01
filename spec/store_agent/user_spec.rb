require "spec_helper"

RSpec.describe StoreAgent::User do
  context "初期化のテスト" do
    context "通常 User の初期化" do
      it "パラメータが無い User を作成しようとするとエラーになる" do
        expect do
          StoreAgent::User.new
        end.to raise_error(ArgumentError)
      end
      it "パラメータが文字列やシンボル、その配列でない場合はエラーになる" do
        expect do
          StoreAgent::User.new(foo: :bar)
        end.to raise_error
      end
      it "パラメータに文字列が渡された場合、guest でないユーザーになる" do
        expect(StoreAgent::User.new("hoge").guest?).to be false
      end
      it "パラメータが文字列またはシンボルの配列なら User 作成できる" do
        expect(StoreAgent::User.new(["hoge"]).identifiers).to eq ["hoge"]
        expect(StoreAgent::User.new([:foo]).identifiers).to eq [:foo]
      end
      it "パラメータが配列を含む配列の場合、一次元配列に変換される" do
        expect(StoreAgent::User.new("hoge", [:foo]).identifiers).to eq ["hoge", :foo]
      end
      it "パラメータの要素に空文字列が含まれる User は作成できない" do
        expect do
          StoreAgent::User.new(["hoge", ""])
        end.to raise_error
      end
      it "パラメータの要素に空シンボルが含まれる User は作成できない" do
        expect do
          StoreAgent::User.new(["hoge", :""])
        end.to raise_error
      end
      it "パラメータの要素に文字列やシンボル以外が含まれる User は作成できない" do
        expect do
          StoreAgent::User.new("hoge", false)
        end.to raise_error
        expect do
          StoreAgent::User.new(0)
        end.to raise_error
      end
      it "パラメータに / が入っている文字列が含まれる User は作成できない" do
        expect do
          StoreAgent::User.new("foo/bar", "hoge")
        end.to raise_error
      end
      it "パラメータに Superuser の identifier が含まれる User は作成できない" do
        expect do
          StoreAgent::User.new("hoge", "root")
        end.to raise_error
        expect do
          StoreAgent::User.new("hoge", :root)
        end.to raise_error
      end
      it "パラメータに Guest の identifier が含まれる User は作成できない" do
        expect do
          StoreAgent::User.new("hoge", "nobody")
        end.to raise_error
        expect do
          StoreAgent::User.new("hoge", :nobody)
        end.to raise_error
      end
      it "User は super_user? ではない" do
        expect(StoreAgent::User.new("foo").super_user?).to be false
      end
    end

    context "Superuser の初期化" do
      it "Superuser はパラメータ無しでも作成できる" do
        expect(StoreAgent::Superuser.new.identifiers).to eq ["root"]
      end
      it "Superuser はパラメータを渡しても無視される" do
        expect(StoreAgent::Superuser.new(:foo).identifiers).to eq ["root"]
      end
      it "Superuser は super_user?" do
        expect(StoreAgent::Superuser.new.super_user?).to be true
      end
    end
  end
end
