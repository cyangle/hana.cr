require "../spec_helper"

describe Hana::Pointer do
  describe ".initialize" do
    context "mutate to_a" do
      it "does not impact original" do
        pointer = Hana::Pointer.new("/foo/bar/baz")
        x = pointer.to_a
        x << "omg"
        x.should eq %w{foo bar baz omg}
        pointer.to_a.should eq %w{foo bar baz}
      end
    end

    context "with many path segments" do
      it "splits them correctly" do
        pointer = Hana::Pointer.new("/foo/bar/baz")
        pointer.to_a.should eq %w{foo bar baz}
      end
    end

    context "with trailing slash" do
      it "splits them correctly" do
        pointer = Hana::Pointer.new("/foo/")
        pointer.to_a.should eq ["foo", ""]
      end
    end

    context "with root path" do
      it "splits them correctly" do
        pointer = Hana::Pointer.new("/")
        pointer.to_a.should eq [""]
      end
    end

    context "with escaped /" do
      it "splits them correctly" do
        pointer = Hana::Pointer.new("/f^/oo/bar")
        pointer.to_a.should eq ["f/oo", "bar"]
      end
    end

    context "with escaped ^" do
      it "splits them correctly" do
        pointer = Hana::Pointer.new("/f^^oo/bar")
        pointer.to_a.should eq ["f^oo", "bar"]
      end
    end
  end

  describe "#eval" do
    context "eval on json object" do
      context "with one segment" do
        it "gets correct value" do
          pointer = Hana::Pointer.new "/foo"
          doc = JSON.parse(%({"foo":"bar"}))
          pointer.eval(doc).should eq "bar"
        end
      end

      context "with many segments" do
        it "gets correct value" do
          pointer = Hana::Pointer.new "/foo/bar"
          doc = JSON.parse(%({"foo":{"bar":"baz"}}))
          pointer.eval(doc).should eq "baz"
        end

        context "first segment is missing" do
          it "returns nil" do
            pointer = Hana::Pointer.new "/baz/foo/bar"
            doc = JSON.parse(%({"foo":"bar"}))
            pointer.eval(doc).should eq nil
          end
        end

        context "second segment is missing" do
          it "returns nil" do
            pointer = Hana::Pointer.new "/foo/bar/baz"
            doc = JSON.parse(%({"foo":null}))
            pointer.eval(doc).should eq nil
          end
        end
      end

      context "with number as object key" do
        it "gets correct value" do
          pointer = Hana::Pointer.new "/foo/1"
          doc = JSON.parse(%({"foo":{"1":"baz"}}))
          pointer.eval(doc).should eq "baz"
        end
      end
    end

    context "eval on json array" do
      context "with one level deep" do
        it "gets correct value" do
          pointer = Hana::Pointer.new "/foo/1"
          doc = JSON.parse(%({"foo":["bar","baz"]}))
          pointer.eval(doc).should eq "baz"
        end
      end

      context "with two levels deep" do
        it "gets correct value" do
          pointer = Hana::Pointer.new "/foo/0/bar"
          doc = JSON.parse(%({"foo":[{"bar":"omg"},"baz"]}))
          pointer.eval(doc).should eq "omg"
        end
      end
    end
  end
end
