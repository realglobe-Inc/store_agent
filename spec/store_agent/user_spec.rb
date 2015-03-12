require "spec_helper"

RSpec.describe StoreAgent::User do
  context "初期化のテスト" do
    context "一般 User の初期化" do
      context "作成成功するケース" do
        it "パラメータに文字列が渡された場合、一般ユーザーになる" do
          expect(StoreAgent::User.new("hoge").guest?).to be false
        end
        it "パラメータが文字列またはシンボルなら文字列に変換されて User 作成される" do
          expect(StoreAgent::User.new("hoge").identifiers).to eq ["hoge"]
          expect(StoreAgent::User.new(:foo, :bar).identifiers).to eq ["foo", "bar"]
        end
        it "パラメータが配列を含む場合、要素が一つだけの配列は文字列に変換される" do
          expect(StoreAgent::User.new("hoge", ["foo"]).identifiers).to eq ["hoge", "foo"]
          expect(StoreAgent::User.new("hoge", [:foo]).identifiers).to eq ["hoge", "foo"]
        end
        it "パラメータが配列を含む場合、要素が二つ以上なら identifiers に配列として追加される" do
          expect(StoreAgent::User.new("hoge", [:foo, "bar"]).identifiers).to eq ["hoge", ["foo", "bar"]]
        end
        it "パラメータの最後が要素が二つ以上の配列の場合、その先頭要素が identifier になる" do
          expect(StoreAgent::User.new("hoge", [:foo, "bar"]).identifier).to eq "foo"
        end
        it "一般の User は super_user? ではない" do
          expect(StoreAgent::User.new("foo").super_user?).to be false
        end
      end

      context "作成失敗するケース" do
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
        it "パラメータの要素に空文字列が含まれる User は作成できない" do
          expect do
            StoreAgent::User.new("hoge", "")
          end.to raise_error
        end
        it "パラメータの要素に空シンボルが含まれる User は作成できない" do
          expect do
            StoreAgent::User.new("hoge", :"")
          end.to raise_error
        end
        it "パラメータの要素に空配列が含まれる User は作成できない" do
          expect do
            StoreAgent::User.new("hoge", [])
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

    context "Guest の初期化" do
      it "Guest はパラメータ無しでも作成できる" do
        expect(StoreAgent::Guest.new.identifiers).to eq ["nobody"]
      end
      it "Guest はパラメータを渡しても無視される" do
        expect(StoreAgent::Guest.new(:foo).identifiers).to eq ["nobody"]
      end
      it "Guest は guest?" do
        expect(StoreAgent::Guest.new.guest?).to be true
      end
    end
  end
end
