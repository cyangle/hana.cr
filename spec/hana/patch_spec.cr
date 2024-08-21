require "../spec_helper"

describe Hana::Patch do
  describe "#apply" do
    context "with invalid op" do
      it "raises an error" do
        expect_raises(Hana::Patch::Error, "bad method `eval`") do
          patch = Hana::Patch.new(%([{"op": "eval", "value": "1"}]))
          doc = JSON.parse(%({"foo":"bar"}))
          patch.apply(doc)
        end
      end
    end

    context "remove missing object key" do
      it "raises an error" do
        expect_raises(
          Hana::Patch::MissingTargetException,
          "key 'missing_key' not found"
        ) do
          patch = Hana::Patch.new(%([{"op": "remove", "path": "/missing_key"}]))
          doc = JSON.parse(%({"foo":"bar"}))
          patch.apply(doc)
        end
      end
    end

    context "remove deep missing path" do
      it "raises an error" do
        expect_raises(
          Hana::Patch::MissingTargetException,
          "key 'missing_key2' not found"
        ) do
          patch = Hana::Patch.new(
            %([{"op": "remove", "path": "/missing_key1/missing_key2"}])
          )
          doc = JSON.parse(%({"foo":"bar"}))
          patch.apply(doc)
        end
      end
    end

    context "remove missing array index" do
      it "raises an error" do
        expect_raises(
          Hana::Patch::OutOfBoundsException,
          "key '1' is out of bounds for array"
        ) do
          patch = Hana::Patch.new(
            %([{"op": "remove", "path": "/1"}])
          )
          doc = JSON.parse(%([0]))
          patch.apply(doc)
        end
      end
    end

    context "remove missing object key in array" do
      it "raises an error" do
        expect_raises(
          Hana::Patch::MissingTargetException,
          "key 'baz' not found"
        ) do
          patch = Hana::Patch.new(
            %([{"op": "remove", "path": "/1/baz"}])
          )
          doc = JSON.parse(%([{"foo": "bar"}, {"foo": "bar"}]))
          patch.apply(doc)
        end
      end
    end

    context "replace missing key" do
      it "raises an error" do
        expect_raises(
          Hana::Patch::MissingTargetException,
          "key 'field' not found"
        ) do
          patch = Hana::Patch.new(
            %([{"op": "replace", "path": "/missing_key/field", "value": "asdf"}])
          )
          doc = JSON.parse(%({"foo": "bar"}))
          patch.apply(doc)
        end
      end
    end
  end
end
