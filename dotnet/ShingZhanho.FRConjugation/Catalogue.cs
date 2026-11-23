using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

namespace ShingZhanho.FRConjugation {
    internal sealed class Catalogue {
        internal sealed class Entry {
            internal VerbEntry Metadata {
                get;
            }
            internal int Model {
                get;
            }
            internal Entry(VerbEntry metadata, int model) {
                Metadata = metadata;
                Model = model;
            }
        }
        private sealed class Operation {
            internal string Prefix = "", Suffix = "";
            internal int Trim;
        }
        internal readonly string[] Slots;
        internal readonly Dictionary<string, int> SlotIds;
        internal readonly Dictionary<string, Entry> Entries = new Dictionary<string, Entry>(StringComparer.Ordinal);
        internal readonly Dictionary<string, List<int>> Homonyms = new Dictionary<string, List<int>>(StringComparer.Ordinal);
        private readonly Dictionary<string, int> suffixes = new Dictionary<string, int>(StringComparer.Ordinal);
        private readonly List<int[]> templates = new List<int[]>();
        private readonly List<int[]> blocks = new List<int[]>();
        private readonly List<Operation[]> programs = new List<Operation[]>();
        private readonly int[] fallbacks;

        internal Catalogue() {
            using var stream = typeof(Catalogue).Assembly.GetManifestResourceStream("ShingZhanho.FRConjugation.catalogue.fcr")
                ?? throw new InvalidDataException("Bundled catalogue is missing");
            using var memory = new MemoryStream();
            stream.CopyTo(memory);
            byte[] bytes = memory.ToArray();
            int Word(int at) {
                if (at < 0 || at > bytes.Length - 4)
                    throw new InvalidDataException("Invalid catalogue offset");
                return bytes[at] | bytes[at + 1] << 8 | bytes[at + 2] << 16 | bytes[at + 3] << 24;
            }
            if (bytes.Length < 40 || Encoding.ASCII.GetString(bytes, 0, 4) != "FCR1" || Word(4) != 1)
                throw new InvalidDataException("Invalid catalogue header");
            int[] sections = Enumerable.Range(0, 8).Select(i => Word(8 + i * 4)).ToArray();
            if (sections[0] != 40 || sections[7] != bytes.Length ||
                Enumerable.Range(0, 7).Any(i => sections[i] > sections[i + 1]))
                throw new InvalidDataException("Invalid catalogue directory");
            (int Start, int End) Record(int section, int index) {
                int at = sections[section];
                int payload = checked(at + 8 + Word(at) * 4);
                int start = checked(payload + Word(at + 4 + index * 4));
                int end = checked(payload + Word(at + 8 + index * 4));
                if (start < payload || end < start || end > sections[section + 1])
                    throw new InvalidDataException("Invalid catalogue record");
                return (start, end);
            }
            var strings = new List<string>();
            for (int i = 0; i < Word(sections[0]); i++) {
                var range = Record(0, i);
                strings.Add(Encoding.UTF8.GetString(bytes, range.Start, range.End - range.Start));
            }
            var slots = new List<string>();
            for (int at = sections[1]; at < sections[2]; at += 4)
                slots.Add(strings[Word(at)]);
            Slots = slots.ToArray();
            SlotIds = slots.Select((slot, index) => (slot, index)).ToDictionary(x => x.slot, x => x.index, StringComparer.Ordinal);
            if (Slots.Length == 0)
                throw new InvalidDataException("No slots");
            for (int at = sections[3]; at < sections[4]; at += 8)
                suffixes.Add(strings[Word(at)], Word(at + 4));
            int width = (Slots.Length + 15) / 16;
            for (int at = sections[4]; at < sections[5]; at += width * 4) {
                var row = new int[width];
                for (int i = 0; i < width; i++)
                    row[i] = Word(at + i * 4);
                templates.Add(row);
            }
            for (int at = sections[5]; at < sections[6]; at += 64) {
                var row = new int[16];
                for (int i = 0; i < 16; i++)
                    row[i] = Word(at + i * 4);
                blocks.Add(row);
            }
            for (int i = 0; i < Word(sections[6]); i++) {
                var range = Record(6, i);
                var row = new List<Operation>();
                for (int at = range.Start; at < range.End; at += 12)
                    row.Add(new Operation { Prefix = strings[Word(at)], Trim = Word(at + 4), Suffix = strings[Word(at + 8)] });
                programs.Add(row.ToArray());
            }
            var frequencies = new Dictionary<int, int>();
            for (int at = sections[2]; at < sections[3]; at += 12) {
                string key = strings[Word(at)];
                int model = Models(key).First();
                int variant = Word(at + 8);
                Entries.Add(key, new Entry(new VerbEntry(key, Word(at + 4), variant == -1 ? null : strings[variant]), model));
                frequencies[model] = frequencies.TryGetValue(model, out int count) ? count + 1 : 1;
                var parts = LemmaIndex(key);
                if (parts.Index.Length != 0) {
                    if (!Homonyms.TryGetValue(parts.Lemma, out var indices))
                        Homonyms[parts.Lemma] = indices = new List<int>();
                    indices.Add(int.Parse(parts.Index, System.Globalization.CultureInfo.InvariantCulture));
                }
            }
            foreach (var indices in Homonyms.Values)
                indices.Sort();
            var ranked = frequencies.Keys.OrderByDescending(i => frequencies[i]).ThenBy(i => i).ToArray();
            fallbacks = Enumerable.Range(0, Slots.Length).Select(slot => ranked.First(model => Program(model, slot) != 0)).ToArray();
        }
        internal static (string Lemma, string Index) LemmaIndex(string key) {
            int at = key.LastIndexOf('_');
            string index = key.Substring(at + 1);
            return at > 0 && index.Length > 0 && index.All(c => c >= '0' && c <= '9')
                ? (key.Substring(0, at), index) : (key, "");
        }
        internal string Resolve(string input, int? homonym) {
            if (Entries.ContainsKey(input) || !Homonyms.TryGetValue(input, out var indices))
                return input;
            return input + "_" + (homonym ?? indices[0]).ToString(System.Globalization.CultureInfo.InvariantCulture);
        }
        private IEnumerable<int> Models(string key) {
            var parts = LemmaIndex(key);
            string marked = "^" + parts.Index + "|" + parts.Lemma;
            int at = 0;
            while (true) {
                if (suffixes.TryGetValue(marked.Substring(at), out int model))
                    yield return model;
                if (at == marked.Length)
                    yield break;
                at += char.IsHighSurrogate(marked[at]) && at + 1 < marked.Length && char.IsLowSurrogate(marked[at + 1]) ? 2 : 1;
            }
        }
        private int Program(int model, int slot) => blocks[templates[model][slot / 16]][slot % 16];
        private string? Render(int model, int slot, string lemma, bool fallback = false) {
            int id = Program(model, slot);
            if (id == 0)
                return null;
            var boundaries = new List<int> { 0 };
            for (int i = 0; i < lemma.Length;) {
                i += char.IsHighSurrogate(lemma[i]) && i + 1 < lemma.Length && char.IsLowSurrogate(lemma[i + 1]) ? 2 : 1;
                boundaries.Add(i);
            }
            var alternatives = new List<string>();
            foreach (var operation in programs[id]) {
                string retained = "";
                if (operation.Trim != -1) {
                    if (operation.Trim >= boundaries.Count) {
                        if (!fallback)
                            return null;
                        retained = lemma;
                    } else
                        retained = lemma.Substring(0, boundaries[boundaries.Count - 1 - operation.Trim]);
                }
                alternatives.Add(operation.Prefix + retained + operation.Suffix);
            }
            string result = string.Join(";", alternatives);
            return fallback && result.Length == 0 ? lemma : result;
        }
        internal string? Raw(string input, int slot, int? homonym, Prediction prediction) {
            if (prediction != Prediction.Inferred) {
                string key = Resolve(input.Normalize(NormalizationForm.FormC), homonym);
                if (Entries.TryGetValue(key, out var entry)) {
                    string? value = Render(entry.Model, slot, LemmaIndex(key).Lemma);
                    if (value != null)
                        return value;
                }
                if (prediction == Prediction.Catalogue)
                    return null;
            }
            string normalized = input.Trim().ToLowerInvariant().Normalize(NormalizationForm.FormC);
            const string alphabet = " '-12;_abcdefghijklmnopqrstuvwxyzâçèéêîïôûœ";
            if (normalized.Length == 0 || normalized.Any(c => alphabet.IndexOf(c) < 0))
                return null;
            string inferredKey = Resolve(normalized, homonym);
            string lemma = LemmaIndex(inferredKey).Lemma;
            foreach (int model in Models(inferredKey)) {
                string? result = Render(model, slot, lemma);
                if (!string.IsNullOrEmpty(result))
                    return result;
            }
            return Render(fallbacks[slot], slot, lemma, true);
        }
    }
}
