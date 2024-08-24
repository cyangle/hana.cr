require "../../src/hana"

class ErrorMapper
  def self.error_class(msg : String) : Class
    case msg
    when /Out of bounds/i         then Hana::Patch::OutOfBoundsException
    when /index is greater than/i then Hana::Patch::OutOfBoundsException
    when /Object operation on array/
      Hana::Patch::ObjectOperationOnArrayException
    when /test op shouldn't get array element/
      Hana::Patch::IndexError | Hana::Patch::ObjectOperationOnArrayException
    when /bad number$/
      Hana::Patch::IndexError | Hana::Patch::ObjectOperationOnArrayException
    when /removing a nonexistent (field|index)/
      Hana::Patch::MissingTargetException | Hana::Patch::OutOfBoundsException
    when /test op should reject the array value, it has leading zeros/
      Hana::Patch::IndexError
    when /missing '(from|value)' parameter/
      KeyError
    when /Unrecognized op 'spam'/
      Hana::Patch::Error
    when /missing 'path'|null is not valid value for 'path'/
      Hana::Patch::InvalidPath
    when /missing|non-existent/
      Hana::Patch::MissingTargetException
    when /JSON Pointer should start with a slash/
      Hana::Pointer::FormatError
    else
      Hana::Patch::FailedTestException
    end
  end
end
