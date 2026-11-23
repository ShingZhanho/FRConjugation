using System;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using JacobS.FRConjugation;

static class Program {
    static void Equal<T>(T actual, T expected) {
        if (!Equals(actual, expected))
            throw new Exception($"Expected {expected ?? (object)"null"}, got {actual ?? (object)"null"}");
    }
    static void Main(string[] args) {
        var c = new Conjugator();
        Conformance.Run(c);
        TypedParity.Run();
        const string slot = "voix_active_avoir|indicatif|present|1pm";
        Equal(c.Entries.Count, 6358);
        Equal(c.Slots.Count, 820);
        Equal(c.HasVerb("ressortir"), true);
        Parallel.For(0, 100, _ => Equal(c.Form("manger", slot), "mangeons"));
        if (args.Length > 0)
            Dump(c, args[0]);
        Console.WriteLine("C# API checks passed");
    }
    static void Dump(Conjugator c, string path) {
        using var file = new BinaryWriter(File.Create(path), Encoding.UTF8);
        void Emit(string? value) {
            byte[]? bytes = value == null ? null : Encoding.UTF8.GetBytes(value);
            file.Write(bytes == null ? uint.MaxValue : (uint)bytes.Length);
            if (bytes != null)
                file.Write(bytes);
        }
        foreach (string slot in c.Slots)
            Emit(slot);
        foreach (var entry in c.Entries.OrderBy(e => e.Key, StringComparer.Ordinal)) {
            Emit(entry.Key);
            Emit(entry.Flags.ToString(System.Globalization.CultureInfo.InvariantCulture));
            Emit(entry.Variant);
            foreach (string slot in c.Slots)
                Emit(c.Form(entry.Key, slot, spelling: Spelling.All));
        }
        foreach (string verb in new[] { "blorper", "x", "er", "_", "manger", "finir", "pleuvoir", "aller", "ressortir_2", "réinventer", "télétravailler" })
            foreach (string slot in c.Slots)
                Emit(c.Form(verb, slot, Prediction.Inferred));
    }
}
