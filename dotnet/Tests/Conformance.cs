using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using JacobS.FRConjugation;

static class Conformance {
    internal static string? Decode(string text) {
        if (text == @"\N")
            return null;
        var result = new StringBuilder();
        for (int i = 0; i < text.Length; i++) {
            if (text[i] != '\\') {
                result.Append(text[i]);
                continue;
            }
            if (++i == text.Length)
                throw new Exception("Truncated escape");
            result.Append(text[i] switch {
                'n' => '\n',
                'r' => '\r',
                't' => '\t',
                '\\' => '\\',
                _ => throw new Exception("Invalid escape")
            });
        }
        return result.ToString();
    }
    internal static void Run(Conjugator c) {
        var lines = File.ReadAllLines(Path.Combine(AppContext.BaseDirectory, "conformance.tsv"));
        if (lines.Length < 2 || lines[0] != "id\toperation\tmode\tverb\tselector\thomonym\tspelling\texpected")
            throw new Exception("Invalid fixture header");
        var ids = new HashSet<string>();
        foreach (string line in lines[1..]) {
            var row = line.Split('\t');
            if (row.Length != 8 || !ids.Add(row[0]))
                throw new Exception("Invalid or duplicate fixture row");
            string verb = Decode(row[3]) ?? throw new Exception("Missing verb");
            string selector = Decode(row[4]) ?? throw new Exception("Missing selector");
            var mode = row[2] switch {
                "catalogue" => Prediction.Catalogue,
                "inferred" => Prediction.Inferred,
                "guess" => Prediction.Guess,
                _ => throw new Exception("Invalid mode")
            };
            int index = int.Parse(row[5], System.Globalization.CultureInfo.InvariantCulture);
            int? homonym = index == 0 ? null : index;
            var spelling = row[6] switch {
                "primary" => Spelling.Primary,
                "alternative" => Spelling.Alternative,
                _ => throw new Exception("Invalid spelling")
            };
            string? actual = row[1] switch {
                "form" => c.Form(verb, selector, mode, homonym, spelling),
                "prefix" => mode switch {
                    Prediction.Catalogue => c.CommonPrefix(verb, homonym),
                    Prediction.Inferred => c.RawInferredCommonPrefix(verb, homonym),
                    _ => c.GuessCommonPrefix(verb, homonym)
                },
                "pronoun" => c.Pronoun(verb, selector, homonym, spelling),
                "with_pronoun" => c.WithPronoun(verb, selector, homonym, spelling),
                "gerondif" => c.Gerondif(verb, selector.Split('|')[0], selector.Split('|')[1], mode, homonym),
                _ => throw new Exception("Unknown operation")
            };
            if (actual != Decode(row[7]))
                throw new Exception($"Conformance case {row[0]} failed; actual={actual ?? "<null>"}");
        }
        Console.WriteLine($"{ids.Count} shared conformance cases passed");
    }
}
