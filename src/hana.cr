require "json"

struct JSON::Any
  def replace(other : JSON::Any)
    @raw = other.raw
  end
end

module Hana
  VERSION = "0.1.0"

  class Error < ::Exception
  end

  class Pointer
    include Enumerable(String)

    class Error < ::Hana::Error
    end

    class FormatError < Error
    end

    @path = [] of String

    def initialize(path)
      @path = Pointer.parse path
    end

    def each(&block)
      @path.each do |part|
        yield part
      end
    end

    def eval(object)
      Pointer.eval @path, object
    end

    ESC = {"^/" => "/", "^^" => "^", "~0" => "~", "~1" => "/"} # :nodoc:

    def self.eval(list : Array(String), object : JSON::Any) : JSON::Any
      result = object
      list.each do |part|
        return result if result.raw.is_a?(Nil)

        if result.raw.is_a?(Array)
          raise Patch::IndexError.new unless part =~ /\A(?:\d|[1-9]\d+)\Z/
          next result = result.as_a[part.to_i]
        end
        result = result.as_h[part]
      end
      result
    end

    def self.parse(path)
      return [""] if path == "/"
      return [] of String if path == ""

      raise FormatError.new("JSON Pointer should start with a slash") unless path.starts_with? "/"

      parts = path.sub(%r{^/}, "").split(%r{(?<!\^)/}).map do |part|
        part.gsub(%r{\^[/^]|~[01]}) { |m| ESC[m] }
      end

      parts.push("") if path[-1] == "/"
      parts
    end
  end

  class Patch
    class Error < ::Hana::Error
    end

    class FailedTestException < Error
      property path : String
      property value : String

      def initialize(path, value)
        super "expected #{value} at #{path}"
        @path = path
        @value = value
      end
    end

    class OutOfBoundsException < Error
    end

    class ObjectOperationOnArrayException < Error
    end

    class InvalidObjectOperationException < Error
    end

    class IndexError < Error
    end

    class MissingTargetException < Error
    end

    class InvalidPath < Error
    end

    @is : Array(Hash(String, ::JSON::Any))

    def initialize(is)
      @is = is
    end

    def apply(doc)
      really_apply doc
    end

    def really_apply(doc)
      new_doc = doc.dup
      @is.each do |ins|
        op = ins["op"].as_s.strip
        case op
        when "add"     then new_doc = add(ins, new_doc)
        when "move"    then new_doc = move(ins, new_doc)
        when "test"    then new_doc = test(ins, new_doc)
        when "replace" then new_doc = replace(ins, new_doc)
        when "remove"  then new_doc = remove(ins, new_doc)
        when "copy"    then new_doc = copy(ins, new_doc)
        else                raise Exception.new("bad method `#{op}`")
        end
      end
      new_doc
    end

    FROM  = "from"  # :nodoc:
    VALUE = "value" # :nodoc:

    def add(ins, doc)
      path = get_path ins
      list = Pointer.parse path
      key = list.pop?
      dest = Pointer.eval list, doc
      obj = ins[VALUE]

      raise MissingTargetException.new("target location '#{ins["path"]}' does not exist") unless dest

      if key
        add_op dest, key, obj
      elsif doc === dest
        doc = obj
      else
        dest.replace obj
      end
      doc
    end

    def move(ins, doc)
      path = get_path ins
      from = Pointer.parse ins[FROM].as_s
      to = Pointer.parse path
      from_key = from.pop?
      key = to.pop?
      src = Pointer.eval from, doc
      dest = Pointer.eval to, doc

      raise MissingTargetException.new("target location '#{ins["path"]}' does not exist") unless dest

      obj = rm_op src, from_key
      add_op dest, key, obj
      doc
    end

    def copy(ins, doc)
      path = get_path ins
      from = Pointer.parse ins[FROM].as_s
      to = Pointer.parse path
      from_key = from.pop
      key = to.pop
      src = Pointer.eval from, doc
      dest = Pointer.eval to, doc

      if src.raw.is_a?(Array)
        unless from_key =~ /\A\d+\Z/
          raise Patch::ObjectOperationOnArrayException.new("cannot apply non-numeric key '#{key}' to array")
        end

        obj = src.as_a[from_key.to_i]
      else
        begin
          obj = src.as_h[from_key]
        rescue ex : Exception
          raise Hana::Patch::MissingTargetException.new("'from' location '#{ins[FROM]}' does not exist")
        end
      end

      raise MissingTargetException.new("target location '#{ins["path"]}' does not exist") unless dest

      add_op dest, key, obj
      doc
    end

    def test(ins, doc)
      path = get_path ins
      expected = Pointer.new(path).eval doc

      raise FailedTestException.new(ins["path"].as_s, ins[VALUE].to_json) unless expected == ins[VALUE]

      doc
    end

    def replace(ins, doc)
      path = get_path ins
      list = Pointer.parse path
      key = list.pop?
      obj = Pointer.eval list, doc

      return ins[VALUE] unless key

      rm_op obj, key
      add_op obj, key, ins[VALUE]
      doc
    end

    def remove(ins, doc)
      path = get_path ins
      list = Pointer.parse path
      key = list.pop?
      obj = Pointer.eval list, doc
      rm_op obj, key
      doc
    end

    def get_path(ins)
      raise Hana::Patch::InvalidPath.new("missing 'path' parameter") unless ins.has_key?("path")

      raise Hana::Patch::InvalidPath.new("null is not valid value for 'path'") unless ins["path"]

      ins["path"].as_s
    end

    def check_index(obj, index)
      key = index.not_nil!
      return -1 if key == "-"

      raise ObjectOperationOnArrayException.new("cannot apply non-numeric key '#{key}' to array") unless key =~ /\A-?\d+\Z/

      idx = key.to_i
      raise OutOfBoundsException.new("key '#{key}' is out of bounds for array") if idx > obj.size || idx < 0

      idx
    end

    def add_op(dest, target_key, obj)
      key = target_key.not_nil!
      if dest.raw.is_a?(Array)
        dest.as_a.insert check_index(dest, key), obj
      else
        raise Patch::InvalidObjectOperationException.new("cannot add key '#{key}' to non-object") unless dest.raw.is_a?(Hash)

        dest.as_h[key] = obj
      end
    end

    def rm_op(obj, from_key)
      key = from_key.not_nil!
      if obj.raw.is_a?(Array)
        unless key =~ /\A\d+\Z/
          raise Patch::ObjectOperationOnArrayException.new("cannot apply non-numeric key '#{key}' to array")
        end

        array = obj.as_a
        index = key.to_i
        raise Patch::OutOfBoundsException.new("key '#{index}' is out of bounds for array") if index >= array.size

        array.delete_at(index)
      else
        hash = obj.as_h
        raise Patch::MissingTargetException.new("key '#{key}' not found") unless hash.try &.has_key? key
        hash.delete(key).not_nil!
      end
    end
  end
end
