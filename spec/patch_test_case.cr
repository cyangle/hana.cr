require "json"

class PatchTestCase
  include JSON::Serializable

  property doc : JSON::Any

  property patch : Array(Hash(String, ::JSON::Any))

  @[JSON::Field(default: nil, required: false, nullable: true, emit_null: false)]
  property expected : JSON::Any?

  @[JSON::Field(default: nil, required: false, nullable: true, emit_null: false)]
  property error : String?

  @[JSON::Field(default: nil, required: false, nullable: true, emit_null: false)]
  property comment : String?

  @[JSON::Field(default: nil, required: false, nullable: true, emit_null: false)]
  property disabled : Bool?

  def self.from_files(paths : Array(String)) : Array(PatchTestCase)
    paths.map do |path|
      File.open(path) do |file|
        Array(PatchTestCase).from_json(file)
      end
    end.flatten
  end

  def initialize(*, @doc, @patch, @expected, @error, @comment, @disabled)
    raise RuntimeError.new("Both of expected and error are missing, set at least one of them!") if expected.nil? && error.nil?
  end
end
