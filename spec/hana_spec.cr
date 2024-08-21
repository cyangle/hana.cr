require "./spec_helper"
require "./patch_test_case"
require "./error_mapper"

describe Hana do
  files = [
    "json-patch-tests/tests.json",
    "json-patch-tests/spec_tests.json",
    "mine.json",
  ].map { |file| File.join(__DIR__, file).to_s }

  tests = PatchTestCase.from_files(files)
  case_number = ENV.fetch("TEST_CASE_NUMBER", "-1").to_i

  tests.each_with_index do |test, index|
    next if case_number > -1 && case_number != index
    next if test.disabled == true
    it "#{index}: #{test.comment.to_s}" do
      # puts "=====#{index}====="
      # pp test
      if expected = test.expected
        patch = Hana::Patch.new test.patch
        result = patch.apply(test.doc)
        result.should eq(expected)
      end

      if error = test.error
        exception = expect_raises(ErrorMapper.error_class(error)) do
          patch = Hana::Patch.new test.patch
          result = patch.apply(test.doc)
        end
      end
    end
  end
end
