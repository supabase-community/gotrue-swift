import Foundation
import Mocker

@testable import GoTrue

func json(named name: String) -> Data {
  let url = Bundle.module.url(forResource: name, withExtension: "json")
  return try! Data(contentsOf: url!)
}

extension Decodable {
  init(fromMockNamed name: String) {
    self = try! JSONDecoder.goTrue.decode(Self.self, from: json(named: name))
  }
}

extension Mock {
  static func post(path: String, json name: String, statusCode: Int = 200) -> Mock {
    Mock(
      url: GoTrueTests.baseURL.appendingPathComponent(path),
      dataType: .json,
      statusCode: statusCode,
      data: [
        .post: json(named: name)
      ]
    )
  }

  static func get(path: String, json name: String, statusCode: Int = 200) -> Mock {
    Mock(
      url: GoTrueTests.baseURL.appendingPathComponent(path),
      dataType: .json,
      statusCode: statusCode,
      data: [
        .get: json(named: name)
      ]
    )
  }
}
