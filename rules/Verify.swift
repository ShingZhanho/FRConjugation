import CryptoKit
import Foundation

private struct Entry: Decodable {
    let key: String
    let flags: Int
    let variant: String?
    let present: Int
    let digest: String
}
private struct Oracle: Decodable { let slots: [String]; let verbs: [Entry] }

private func verify(_ url: URL, _ gold: URL) throws {
    let model = try RuleFile(url)
    let oracle = try JSONDecoder().decode(Oracle.self, from: Data(contentsOf: gold))
    guard oracle.slots == (0..<model.slotCount).map(model.slotName),
        model.verbCount == oracle.verbs.count
    else { throw InvalidFormat("Inventory mismatch") }
    var present = 0, absent = 0
    for (i, ref) in oracle.verbs.enumerated() {
        let metadata = model.metadata(at: i)
        guard metadata.0 == ref.key, metadata.1 == ref.flags, metadata.2 == ref.variant,
            let selected = model.select(ref.key)
        else { throw InvalidFormat(ref.key) }
        var row = Data()
        var count = 0
        for slot in oracle.slots.indices {
            let answer = model.render(selected, slot)
            var length = (answer.map { UInt32($0.utf8.count) } ?? UInt32.max).littleEndian
            withUnsafeBytes(of: &length) { row.append(contentsOf: $0) }
            if let answer {
                row.append(contentsOf: answer.utf8)
                count += 1
            }
        }
        let digest = SHA256.hash(data: row).map { String(format: "%02x", $0) }.joined()
        guard count == ref.present, digest == ref.digest else {
            throw InvalidFormat("Output mismatch for \(ref.key)")
        }
        present += count
        absent += model.slotCount - count
    }
    print("Verified \(model.verbCount) entries, \(present) forms and \(absent) missing slots.")
}

@main
private enum CatalogueVerifier {
    static func main() throws {
        guard CommandLine.arguments.count == 3 else {
            throw InvalidFormat("Usage: verify-catalogue CATALOGUE.fcr ORACLE.json")
        }
        try verify(
            URL(fileURLWithPath: CommandLine.arguments[1]),
            URL(fileURLWithPath: CommandLine.arguments[2]))
    }
}
