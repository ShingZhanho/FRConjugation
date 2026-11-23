import Foundation

@main enum SwiftOracle {
    static func main() throws {
        let file = try RuleFile(URL(fileURLWithPath: CommandLine.arguments[1]))
        let catalogue = try RuleCatalogue(url: URL(fileURLWithPath: CommandLine.arguments[1]))
        var buffer = Data()
        func emit(_ value: String?) {
            var length = (value.map { UInt32($0.utf8.count) } ?? UInt32.max).littleEndian
            withUnsafeBytes(of: &length) { buffer.append(contentsOf: $0) }
            if let value { buffer.append(contentsOf: value.utf8) }
            if buffer.count >= 65536 {
                FileHandle.standardOutput.write(buffer)
                buffer.removeAll(keepingCapacity: true)
            }
        }
        for slot in 0..<file.slotCount { emit(file.slotName(slot)) }
        for index in 0..<file.verbCount {
            let (key, flags, variant) = file.metadata(at: index)
            emit(key)
            emit(String(flags))
            emit(variant)
            let selected = file.select(key)!
            for slot in 0..<file.slotCount { emit(file.render(selected, slot)) }
        }
        for verb in [
            "blorper", "x", "er", "_", "manger", "finir", "pleuvoir",
            "aller", "ressortir_2", "réinventer", "télétravailler",
        ] {
            for slot in catalogue.slots { emit(catalogue.infer(verb, slot: slot)) }
        }
        FileHandle.standardOutput.write(buffer)
    }
}
