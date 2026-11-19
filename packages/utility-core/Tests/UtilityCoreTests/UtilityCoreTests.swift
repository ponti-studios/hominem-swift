import XCTest

@testable import UtilityCore

final class UtilityCoreTests: XCTestCase {
  func testCSVQuotedFieldsAndCRLF() {
    let csv =
      "name,address\r\n\"O'Brien's Cafe\",\"1 Main St, London\"\r\nPark,\"2, Park Road\"\r\n"
    let table = CSVTable(text: csv)

    XCTAssertEqual(table.count, 2)
    XCTAssertEqual(table.rows[0]["address"], "1 Main St, London")
    XCTAssertEqual(table.rows[1]["address"], "2, Park Road")
  }

  func testStableIDIsRepeatable() {
    let first = StableID.uuid("place|blue bottle|51.5|-0.1")
    let second = StableID.uuid("place|blue bottle|51.5|-0.1")

    XCTAssertEqual(first, second)
  }
}
