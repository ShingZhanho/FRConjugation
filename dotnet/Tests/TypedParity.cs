using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Threading.Tasks;
using JacobS.FRConjugation;

static class TypedParity {
    static string Label(object value) => value switch { Voice v => v.Label(), Mode m => m.Label(), Tense t => t.Label(), Person p => p.Label(), _ => value.ToString()! };
    static object? Call(Conjugator c, string name, params object?[] args) {
        var method = typeof(Conjugator).GetMethods().Single(m => m.Name == name && m.GetParameters().Length == args.Length && m.GetParameters().Zip(args, (p, a) => a == null || p.ParameterType.IsInstanceOfType(a)).All(x => x));
        return method.Invoke(c, args);
    }
    static string? Flatten(object? value, List<string>? prefix = null) {
        if (value == null || value is string)
            return (string?)value;
        var lines = new List<string>();
        void Walk(IDictionary node, List<string> path) {
            foreach (DictionaryEntry entry in node) {
                var keys = new List<string>(path) { Label(entry.Key) };
                if (entry.Value is IDictionary child)
                    Walk(child, keys);
                else
                    lines.Add(string.Join("|", keys) + "=" + entry.Value);
            }
        }
        Walk((IDictionary)value, prefix ?? new List<string>());
        return string.Join("\n", lines.OrderBy(s => s, StringComparer.Ordinal));
    }
    internal static void Run() {
        var c = new Conjugator();
        int count = 0;
        foreach (var line in File.ReadAllLines(Path.Combine(AppContext.BaseDirectory, "typed-api.tsv")).Skip(1)) {
            var r = line.Split('\t');
            var actual = Evaluate(c, r);
            var expected = Conformance.Decode(r[9]);
            if (actual != expected)
                throw new Exception($"Typed case {r[0]} ({r[1]}) failed: {actual}");
            count++;
        }
        AsyncChecks(c).GetAwaiter().GetResult();
        Console.WriteLine($"{count} typed Swift parity cases and async checks passed");
    }
    static string? Evaluate(Conjugator c, string[] r) {
        string op = r[1], verb = r[2];
        var types = new[] { typeof(Voice), typeof(Mode), typeof(Tense), typeof(Person) };
        var selectors = Enumerable.Range(0, 4).Select(i => r[i + 3] == "-" ? null : Enum.GetValues(types[i]).Cast<object>().Single(x => Label(x) == r[i + 3])).ToArray();
        int? h = r[7] == "0" ? null : int.Parse(r[7]);
        if (op.StartsWith("enum_"))
            return string.Join(",", Enum.GetValues(types[Array.IndexOf(new[] { "enum_voice", "enum_mode", "enum_tense", "enum_person" }, op)]).Cast<object>().Select(Label));
        if (op == "person_pronouns")
            return string.Join(",", Enum.GetValues(typeof(Person)).Cast<Person>().Select(p => p.Pronoun()));
        if (op == "all_verbs")
            return string.Join(",", c.AllVerbs);
        if (op == "verb_count")
            return c.VerbCount.ToString();
        var names = new Dictionary<string, string> { { "has_verb", "HasVerb" }, { "has_homonyms", "HasHomonyms" }, { "homonym_count", "HomonymCount" }, { "homonym_indices", "HomonymIndices" }, { "h_aspire", "IsHAspire" }, { "blocking", "BlocksElisionAndLiaison" }, { "reform", "Is1990Reform" }, { "variant", "ReformVariant" } };
        if (names.TryGetValue(op, out var name)) {
            object? value = op == "blocking" ? Call(c, name, verb, h) : Call(c, name, verb);
            return value is bool b ? (b ? "1" : "0") : value is IEnumerable<int> ints ? string.Join(",", ints) : value?.ToString();
        }
        int structure = Array.IndexOf(new[] { "voices", "modes", "tenses", "persons" }, op);
        if (structure >= 0) {
            var args = new List<object?> { verb };
            args.AddRange(selectors.Take(structure));
            args.Add(h);
            var values = (IEnumerable)Call(c, char.ToUpperInvariant(op[0]) + op.Substring(1), args.ToArray())!;
            return string.Join(",", values.Cast<object>().Select(Label));
        }
        var methods = new Dictionary<string, string> { { "alternative", "ConjugateAlternative" }, { "has_alternative", "HasAlternativeForm" }, { "participle_alternative", "ParticipleAlternative" }, { "has_alternative_participle", "HasAlternativeParticiple" }, { "pronoun", "GetPronoun" }, { "with_pronoun", "ConjugateWithPronoun" }, { "alternative_with_pronoun", "ConjugateAlternativeWithPronoun" } };
        if (methods.TryGetValue(op, out name)) {
            var args = new List<object?> { verb };
            args.AddRange(op.Contains("participle") ? new[] { selectors[0], selectors[2] } : selectors);
            args.Add(h);
            var value = Call(c, name, args.ToArray());
            return value is bool b ? (b ? "1" : "0") : (string?)value;
        }
        string prefix = r[8] == "inferred" ? "RawInferred" : r[8] == "guess" ? "Guess" : "";
        if (op == "finite") {
            var chosen = selectors.TakeWhile(x => x != null).ToArray();
            var args = new List<object?> { verb };
            args.AddRange(chosen);
            args.Add(h);
            return Flatten(Call(c, prefix.Length == 0 ? "Conjugate" : prefix + "Conjugation", args.ToArray()), chosen.Select(x => Label(x!)).ToList());
        }
        var arguments = new List<object?> { verb, selectors[0] };
        if (op != "participles")
            arguments.Add(selectors[2]);
        arguments.Add(h);
        return Flatten(Call(c, prefix + char.ToUpperInvariant(op[0]) + op.Substring(1), arguments.ToArray()));
    }
    static async Task AsyncChecks(Conjugator c) {
        if (!ReferenceEquals(await Conjugator.GetSharedAsync(), Conjugator.GetShared()))
            throw new Exception("Shared identity");
        var loaded = await Conjugator.LoadAsync();
        foreach (var method in typeof(Conjugator).GetMethods().Where(m => m.Name.EndsWith("Async") && !m.IsStatic)) {
            object?[] args = method.GetParameters().Select(p => p.ParameterType == typeof(string) ? (object)"manger" : p.ParameterType == typeof(Voice) ? Voice.ActiveAvoir : p.ParameterType == typeof(Mode) ? Mode.Indicatif : p.ParameterType == typeof(Tense) ? (method.Name.Contains("Gerondif") ? Tense.GerondifPresent : method.Name.Contains("Participle") ? Tense.PasseFemininPluriel : Tense.Present) : p.ParameterType == typeof(Person) ? Person.FirstPluralMasculine : null).ToArray();
            var task = (Task)method.Invoke(loaded, args)!;
            await task;
            var actual = task.GetType().GetProperty("Result")!.GetValue(task);
            var expected = Call(c, method.Name.Substring(0, method.Name.Length - 5), args);
            if (Flatten(actual) != Flatten(expected))
                throw new Exception("Async mismatch: " + method.Name);
        }
    }
}
