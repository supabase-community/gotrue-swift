import CustomDump
import Foundation

func stringfy(_ value: Any) -> String {
  var output = ""
  customDump(value, to: &output)
  return output
}
