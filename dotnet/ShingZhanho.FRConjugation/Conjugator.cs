using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace ShingZhanho.FRConjugation {
    /// <summary>Selects catalogue lookup, raw rule inference, or catalogue-first guessing.</summary>
    public enum Prediction {
        /// <summary>Exact Trimmed, lowercase, NFC-normalized catalogue lookup.</summary>
        Catalogue,
        /// <summary>Normalize and infer supported inputs, including unknown verbs. Results may be unattested.</summary>
        Inferred,
        /// <summary>Use catalogue data for known infinitives; infer only unknown infinitives.</summary>
        Guess
    }
    /// <summary>Selects catalogue spellings; raw predictions always retain all alternatives.</summary>
    public enum Spelling {
        /// <summary>First semicolon-separated spelling.</summary>
        Primary,
        /// <summary>Remainder after the first semicolon, or the primary spelling if absent.</summary>
        Alternative,
        /// <summary>All spellings separated by semicolons.</summary>
        All
    }
    /// <summary>Immutable metadata for a catalogue entry, including indexed homonyms.</summary>
    public sealed class VerbEntry {
        /// <summary>Exact infinitive key, including any numeric homonym suffix such as ressortir_2.</summary>
        public string Key {
            get;
        }
        /// <summary>Source flags: bit 0 h aspiré, bit 1 elision/liaison blocking, bit 2 1990 reform.</summary>
        public int Flags {
            get;
        }
        /// <summary>Source reform-variant key, or null when none is recorded.</summary>
        public string? Variant {
            get;
        }
        /// <summary>Whether an initial h blocks elision and liaison.</summary>
        /// <exception cref="ArgumentOutOfRangeException">A homonym index is not positive or an enum value is invalid for this operation.</exception>
        /// <exception cref="ArgumentNullException">A required string argument is null.</exception>
        public bool IsHAspire => (Flags & 1) != 0;
        /// <summary>Whether the source blocks lexical elision/liaison, including non-h initials. Auxiliaries may still elide.</summary>
        /// <exception cref="ArgumentOutOfRangeException">A homonym index is not positive or an enum value is invalid for this operation.</exception>
        /// <exception cref="ArgumentNullException">A required string argument is null.</exception>
        public bool BlocksElisionAndLiaison => (Flags & 2) != 0;
        /// <summary>Whether the entry is marked as a 1990 spelling reform variant.</summary>
        /// <exception cref="ArgumentOutOfRangeException">A homonym index is not positive or an enum value is invalid for this operation.</exception>
        /// <exception cref="ArgumentNullException">A required string argument is null.</exception>
        public bool Is1990Reform => (Flags & 4) != 0;
        internal VerbEntry(string key, int flags, string? variant) {
            Key = key;
            Flags = flags;
            Variant = variant;
        }
    }

    /// <summary>Thread-safe bundled conjugation rules. Synchronous calls run on the caller;
    /// Async-suffixed methods dispatch to the thread pool without cancellation.
    /// Slots use voice|mode|tense|person, with "-" for participles.
    /// Null means missing. An empty prefix is a valid result.</summary>
    /// <remarks>Catalogue reads are synchronous. Inference accepts only the bundled alphabet after
    /// trimming, lowercasing and NFC normalization: space, apostrophe, hyphen, 1, 2, semicolon,
    /// underscore, a-z and âçèéêîïôûœ. No custom catalogue can be supplied.
    /// Initialization failures propagate from loading the embedded resource.</remarks>
    public sealed partial class Conjugator {
        private static readonly Lazy<Catalogue> Bundled = new Lazy<Catalogue>(() => { try { return new Catalogue(); } catch (Exception error) when (!(error is OutOfMemoryException)) { throw new ConjugationException("Failed to load bundled conjugation catalogue", error); } });
        private readonly Catalogue catalogue = Bundled.Value;
        /// <summary>Creates a reader sharing the lazily loaded embedded catalogue.</summary>
        /// <exception cref="ConjugationException">The bundled catalogue is missing or invalid.</exception>
        public Conjugator() {
        }
        /// <summary>All supported voice|mode|tense|person labels in catalogue order; participles use - as person.</summary>
        /// <exception cref="ArgumentOutOfRangeException">A homonym index is not positive or an enum value is invalid for this operation.</exception>
        /// <exception cref="ArgumentNullException">A required string argument is null.</exception>
        public IReadOnlyList<string> Slots => Array.AsReadOnly(catalogue.Slots);
        /// <summary>A snapshot of all catalogue entries, including separately indexed homonyms.</summary>
        /// <exception cref="ArgumentOutOfRangeException">A homonym index is not positive or an enum value is invalid for this operation.</exception>
        /// <exception cref="ArgumentNullException">A required string argument is null.</exception>
        public IReadOnlyList<VerbEntry> Entries => catalogue.Entries.Values.Select(e => e.Metadata).ToArray();
        /// <summary>Distinct base infinitives in French-oriented accent/ligature-insensitive order, collapsing homonym suffixes.</summary>
        /// <exception cref="ArgumentOutOfRangeException">A homonym index is not positive or an enum value is invalid for this operation.</exception>
        /// <exception cref="ArgumentNullException">A required string argument is null.</exception>
        public IReadOnlyList<string> AllVerbs => Entries.Select(e => Catalogue.LemmaIndex(e.Key).Lemma).Distinct().OrderBy(SortKey, StringComparer.Ordinal).ThenBy(s => s, StringComparer.Ordinal).ToArray();
        /// <summary>Tests normalized catalogue membership, accepting either base infinitives or indexed homonym keys.</summary>
        /// <param name="verb">Infinitive or exact indexed key. Verb input is trimmed, lowercased and NFC-normalized before lookup.</param>
        /// <exception cref="ArgumentNullException">A required string argument is null.</exception>
        public bool HasVerb(string verb) {
            if (verb == null)
                throw new ArgumentNullException(nameof(verb));
            string key = Catalogue.VerbKey(verb);
            return catalogue.Entries.ContainsKey(key) || catalogue.Homonyms.ContainsKey(key);
        }
        /// <summary>Returns ascending indices for a base infinitive, or an empty list when no indexed group exists.</summary>
        /// <param name="verb">Infinitive or exact indexed key. Verb input is trimmed, lowercased and NFC-normalized before lookup.</param>
        /// <exception cref="ArgumentNullException">A required string argument is null.</exception>
        public IReadOnlyList<int> HomonymIndices(string verb) {
            if (verb == null)
                throw new ArgumentNullException(nameof(verb));
            return catalogue.Homonyms.TryGetValue(Catalogue.VerbKey(verb), out var indices)
                ? indices.ToArray() : Array.Empty<int>();
        }
        private static void Validate(string verb, int? homonym, Prediction prediction) {
            if (verb == null)
                throw new ArgumentNullException(nameof(verb));
            if (homonym <= 0)
                throw new ArgumentOutOfRangeException(nameof(homonym));
            if (prediction < Prediction.Catalogue || prediction > Prediction.Guess)
                throw new ArgumentOutOfRangeException(nameof(prediction));
        }
        private static string SelectSpelling(string raw, Spelling spelling) {
            int at = raw.IndexOf(';');
            if (spelling == Spelling.All || at < 0)
                return raw;
            return spelling == Spelling.Primary ? raw.Substring(0, at) : raw.Substring(at + 1);
        }
        /// <summary>Returns one form, or null for an unknown slot, unsupported input, or unavailable catalogue form.</summary>
        /// <param name="verb">Infinitive or exact indexed key. Verb input is trimmed, lowercased and NFC-normalized before lookup.</param>
        /// <param name="slot">Supported voice|mode|tense|person label from Slots, with - for participles.</param>
        /// <param name="prediction">All modes trim, lowercase and NFC-normalize verb inputs; Guess infers only infinitives absent from the catalogue. Predictions can be unattested.</param>
        /// <param name="homonymIndex">Positive homonym index, or null for the first available index. An exact entry key takes precedence.</param>
        /// <param name="spelling">Catalogue spelling selection. Inferred output retains all semicolon-separated alternatives.</param>
        /// <exception cref="ArgumentOutOfRangeException">A homonym index is not positive or an enum value is invalid for this operation.</exception>
        /// <exception cref="ArgumentNullException">A required string argument is null.</exception>
        public string? Form(string verb, string slot, Prediction prediction = Prediction.Catalogue,
                            int? homonymIndex = null, Spelling spelling = Spelling.Primary) {
            Validate(verb, homonymIndex, prediction);
            if (slot == null)
                throw new ArgumentNullException(nameof(slot));
            if (spelling < Spelling.Primary || spelling > Spelling.All)
                throw new ArgumentOutOfRangeException(nameof(spelling));
            if (!catalogue.SlotIds.TryGetValue(slot, out int id))
                return null;
            if (prediction != Prediction.Inferred) {
                string? known = catalogue.Raw(verb, id, homonymIndex, Prediction.Catalogue);
                if (known != null)
                    return SelectSpelling(known, spelling);
                if (prediction == Prediction.Catalogue || HasVerb(verb))
                    return null;
            }
            return catalogue.Raw(verb, id, homonymIndex, Prediction.Inferred);
        }
        /// <summary>Returns supported slots mapped to forms; missing results are omitted. Catalogue spellings are primary.</summary>
        /// <param name="verb">Infinitive or exact indexed key. Verb input is trimmed, lowercased and NFC-normalized before lookup.</param>
        /// <param name="prediction">All modes trim, lowercase and NFC-normalize verb inputs; Guess infers only infinitives absent from the catalogue. Predictions can be unattested.</param>
        /// <param name="homonymIndex">Positive homonym index, or null for the first available index. An exact entry key takes precedence.</param>
        /// <exception cref="ArgumentOutOfRangeException">A homonym index is not positive or an enum value is invalid for this operation.</exception>
        /// <exception cref="ArgumentNullException">A required string argument is null.</exception>
        public IReadOnlyDictionary<string, string> Forms(string verb, Prediction prediction = Prediction.Catalogue, int? homonymIndex = null) {
            var result = new Dictionary<string, string>();
            foreach (string slot in Slots) {
                string? value = Form(verb, slot, prediction, homonymIndex);
                if (value != null)
                    result.Add(slot, value);
            }
            return result;
        }
        /// <summary>Returns shared spelling across all catalogue forms and alternatives, excluding auxiliaries and attached pronouns.</summary>
        /// <param name="verb">Infinitive or exact indexed key. Verb input is trimmed, lowercased and NFC-normalized before lookup.</param>
        /// <param name="homonymIndex">Positive homonym index, or null for the first available index. An exact entry key takes precedence.</param>
        /// <returns>Null if no usable forms exist; an empty string is a valid prefix. This is a display aid, not a grammatical stem.</returns>
        /// <exception cref="ArgumentOutOfRangeException">A homonym index is not positive or an enum value is invalid for this operation.</exception>
        /// <exception cref="ArgumentNullException">A required string argument is null.</exception>
        public string? CommonPrefix(string verb, int? homonymIndex = null) => Prefix(verb, homonymIndex, Prediction.Catalogue);
        /// <summary>Returns shared spelling across raw inferred forms and alternatives, excluding auxiliaries and attached pronouns.</summary>
        /// <param name="verb">Infinitive or exact indexed key. Verb input is trimmed, lowercased and NFC-normalized before lookup.</param>
        /// <param name="homonymIndex">Positive homonym index, or null for the first available index. An exact entry key takes precedence.</param>
        /// <returns>Null if no usable forms exist; an empty string is a valid prefix. This is a display aid, not a grammatical stem.</returns>
        /// <exception cref="ArgumentOutOfRangeException">A homonym index is not positive or an enum value is invalid for this operation.</exception>
        /// <exception cref="ArgumentNullException">A required string argument is null.</exception>
        public string? RawInferredCommonPrefix(string verb, int? homonymIndex = null) => Prefix(verb, homonymIndex, Prediction.Inferred);
        /// <summary>Returns the catalogue prefix for known infinitives, otherwise an inferred prefix.</summary>
        /// <param name="verb">Infinitive or exact indexed key. Verb input is trimmed, lowercased and NFC-normalized before lookup.</param>
        /// <param name="homonymIndex">Positive homonym index, or null for the first available index. An exact entry key takes precedence.</param>
        /// <returns>Null if no usable forms exist; an empty string is a valid prefix. This is a display aid, not a grammatical stem.</returns>
        /// <exception cref="ArgumentOutOfRangeException">A homonym index is not positive or an enum value is invalid for this operation.</exception>
        /// <exception cref="ArgumentNullException">A required string argument is null.</exception>
        public string? GuessCommonPrefix(string verb, int? homonymIndex = null) => Prefix(verb, homonymIndex, Prediction.Guess);
        private static readonly Regex Trailing = new Regex("-(?:(?:m|t)['’]en|moi|toi|nous|vous|le|la|les|lui|leur|en|y)(?:-(?:en|y))?$");
        private static readonly Regex Leading = new Regex("^(?:(?:j|m|t|s|n|l|qu)['’])+");
        private static string MainWord(string form) {
            string[] words = Regex.Split(form.Normalize(NormalizationForm.FormC).Trim(), @"\s+");
            return Leading.Replace(Trailing.Replace(words[words.Length - 1], ""), "");
        }
        private static string SharedPrefix(string a, string b) {
            var left = StringInfo.GetTextElementEnumerator(a);
            var right = StringInfo.GetTextElementEnumerator(b);
            int length = 0;
            while (left.MoveNext() && right.MoveNext() && left.GetTextElement() == right.GetTextElement())
                length += left.GetTextElement().Length;
            return a.Substring(0, length);
        }
        private string? Prefix(string verb, int? homonym, Prediction prediction) {
            Validate(verb, homonym, prediction);
            string? result = null;
            for (int slot = 0; slot < catalogue.Slots.Length; slot++) {
                string? raw = catalogue.Raw(verb, slot, homonym, prediction);
                if (raw == null)
                    continue;
                foreach (string alternative in raw.Split(';')) {
                    string word = MainWord(alternative);
                    if (word.Length == 0)
                        continue;
                    result = result == null ? word : SharedPrefix(result, word);
                    if (result.Length == 0)
                        return result;
                }
            }
            return result;
        }
        private static readonly Dictionary<string, string> GerondifSources = new Dictionary<string, string> {
            {"gerondif_present","present"},{"gerondif_passe_sm","passe_compound_sm"},
            {"gerondif_passe_sf","passe_compound_sf"},{"gerondif_passe_pm","passe_compound_pm"},{"gerondif_passe_pf","passe_compound_pf"}
        };
        /// <summary>Prefixes the underlying participle with en; predictions repeat en for each alternative. Missing forms return null.</summary>
        /// <param name="verb">Infinitive or exact indexed key. Verb input is trimmed, lowercased and NFC-normalized before lookup.</param>
        /// <param name="prediction">All modes trim, lowercase and NFC-normalize verb inputs; Guess infers only infinitives absent from the catalogue. Predictions can be unattested.</param>
        /// <param name="homonymIndex">Positive homonym index, or null for the first available index. An exact entry key takes precedence.</param>
        /// <param name="voice">Catalogue voice label, such as voix_active_avoir or voix_prono.</param>
        /// <param name="tense">gerondif_present or gerondif_passe_sm, gerondif_passe_sf, gerondif_passe_pm, gerondif_passe_pf.</param>
        /// <exception cref="ArgumentOutOfRangeException">A homonym index is not positive or an enum value is invalid for this operation.</exception>
        /// <exception cref="ArgumentNullException">A required string argument is null.</exception>
        public string? Gerondif(string verb, string voice, string tense, Prediction prediction = Prediction.Catalogue, int? homonymIndex = null) {
            Validate(verb, homonymIndex, prediction);
            if (voice == null || tense == null)
                throw new ArgumentNullException(voice == null ? nameof(voice) : nameof(tense));
            if (!GerondifSources.TryGetValue(tense, out string source))
                return null;
            string? value = Form(verb, voice + "|participe|" + source + "|-", prediction, homonymIndex);
            return value == null ? null : string.Join(";", value.Split(';').Select(s => "en " + s.Trim()));
        }
        private static readonly Dictionary<string, string> Subjects = new Dictionary<string, string> {
            {"1sm","je"},{"1sf","je"},{"2sm","tu"},{"2sf","tu"},{"3sm","il"},{"3sf","elle"},{"3sn","on"},
            {"1pm","nous"},{"1pf","nous"},{"2pm","vous"},{"2pf","vous"},{"3pm","ils"},{"3pf","elles"}
        };
        private string? Subject(string verb, string slot, int? homonym, string form) {
            string[] parts = slot.Split('|');
            if (parts.Length != 4 || parts[1] == "imperatif" || parts[1] == "participe")
                return null;
            if (!Subjects.TryGetValue(parts[3], out string subject))
                return null;
            catalogue.Entries.TryGetValue(catalogue.Resolve(Catalogue.VerbKey(verb), homonym), out var entry);
            char first = form.Length == 0 ? '\0' : char.ToLowerInvariant(form[0]);
            bool vowel = "aeiouàâéèêëîïôùûüœæy".IndexOf(first) >= 0;
            if (first == 'h')
                vowel = entry?.Metadata.IsHAspire != true;
            bool simple = parts[2] == "present" || parts[2] == "imparfait" || parts[2] == "passe_simple" || parts[2] == "futur_simple";
            if (parts[0] != "voix_passive" && simple && entry?.Metadata.BlocksElisionAndLiaison == true)
                vowel = false;
            string result = subject == "je" && vowel ? "j'" : subject + " ";
            return parts[1] == "subjonctif" ? (parts[3][0] == '3' ? "qu'" : "que ") + result : result;
        }
        /// <summary>Returns a catalogue subject prefix with its trailing space or apostrophe, including subjunctive que/qu’. Imperatives, participles and unavailable forms return null.</summary>
        /// <param name="verb">Infinitive or exact indexed key. Verb input is trimmed, lowercased and NFC-normalized before lookup.</param>
        /// <param name="slot">Supported voice|mode|tense|person label from Slots, with - for participles.</param>
        /// <param name="homonymIndex">Positive homonym index, or null for the first available index. An exact entry key takes precedence.</param>
        /// <param name="spelling">Primary or Alternative catalogue spelling. All is invalid.</param>
        /// <exception cref="ArgumentOutOfRangeException">A homonym index is not positive or an enum value is invalid for this operation.</exception>
        /// <exception cref="ArgumentNullException">A required string argument is null.</exception>
        public string? Pronoun(string verb, string slot, int? homonymIndex = null, Spelling spelling = Spelling.Primary) {
            if (spelling == Spelling.All)
                throw new ArgumentOutOfRangeException(nameof(spelling));
            string? value = Form(verb, slot, homonymIndex: homonymIndex, spelling: spelling);
            return value == null ? null : Subject(verb, slot, homonymIndex, value);
        }
        /// <summary>Returns a catalogue form with its subject prefix; imperatives and participles remain bare. Missing forms return null.</summary>
        /// <param name="verb">Infinitive or exact indexed key. Verb input is trimmed, lowercased and NFC-normalized before lookup.</param>
        /// <param name="slot">Supported voice|mode|tense|person label from Slots, with - for participles.</param>
        /// <param name="homonymIndex">Positive homonym index, or null for the first available index. An exact entry key takes precedence.</param>
        /// <param name="spelling">Primary or Alternative catalogue spelling. All is invalid.</param>
        /// <exception cref="ArgumentOutOfRangeException">A homonym index is not positive or an enum value is invalid for this operation.</exception>
        /// <exception cref="ArgumentNullException">A required string argument is null.</exception>
        public string? WithPronoun(string verb, string slot, int? homonymIndex = null, Spelling spelling = Spelling.Primary) {
            if (spelling == Spelling.All)
                throw new ArgumentOutOfRangeException(nameof(spelling));
            string? value = Form(verb, slot, homonymIndex: homonymIndex, spelling: spelling);
            return value == null ? null : (Subject(verb, slot, homonymIndex, value) ?? "") + value;
        }
    }
}
