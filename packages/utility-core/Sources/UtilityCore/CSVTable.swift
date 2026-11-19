import Foundation

public struct CSVTable {
  public let headers: [String]
  public let rows: [[String: String]]

  public init(text: String) {
    var records = Self.scan(text)
    guard !records.isEmpty else {
      headers = []
      rows = []
      return
    }
    let parsedHeaders = records.removeFirst().map {
      $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    headers = parsedHeaders
    rows = records.compactMap { record in
      guard record.contains(where: { !$0.isEmpty }) else { return nil }
      var row: [String: String] = [:]
      for (index, header) in parsedHeaders.enumerated() where index < record.count {
        row[header] = record[index]
      }
      return row
    }
  }

  public var count: Int { rows.count }

  public static func scan(_ text: String) -> [[String]] {
    var bytes = Array(text.utf8)
    if bytes.count >= 3,
      bytes[0] == 0xEF,
      bytes[1] == 0xBB,
      bytes[2] == 0xBF
    {
      bytes.removeFirst(3)
    }

    var records: [[String]] = []
    var record: [String] = []
    var field: [UInt8] = []
    var inQuotes = false
    var index = 0

    func endField() {
      record.append(String(decoding: field, as: UTF8.self))
      field.removeAll(keepingCapacity: true)
    }

    func endRecord() {
      endField()
      records.append(record)
      record.removeAll(keepingCapacity: true)
    }

    while index < bytes.count {
      let byte = bytes[index]
      if inQuotes {
        if byte == 0x22 {
          if index + 1 < bytes.count, bytes[index + 1] == 0x22 {
            field.append(0x22)
            index += 1
          } else {
            inQuotes = false
          }
        } else {
          field.append(byte)
        }
      } else {
        switch byte {
        case 0x22:
          inQuotes = true
        case 0x2C:
          endField()
        case 0x0D:
          break
        case 0x0A:
          endRecord()
        default:
          field.append(byte)
        }
      }
      index += 1
    }

    if !field.isEmpty || !record.isEmpty {
      endRecord()
    }
    return records
  }
}
