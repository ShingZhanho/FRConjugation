using System;
using System.Collections.Generic;
using System.Linq;
using System.Globalization;
using System.Text;
namespace ShingZhanho.FRConjugation {
    public sealed partial class Conjugator {
        private static readonly Lazy<Conjugator> Shared = new Lazy<Conjugator>(() => new Conjugator());
        /// <summary>Return the shared bundled reader; loading exceptions propagate.</summary>
        public static Conjugator GetShared() => Shared.Value;
        /// <summary>Distinct base-infinitive count, collapsing homonyms.</summary>
        public int VerbCount => AllVerbs.Count;
        /// <summary>Whether the base name has indexed homonyms.</summary>
        public bool HasHomonyms(string verb) => HomonymIndices(verb).Count != 0;
        /// <summary>Homonym count, or one without an indexed group, including unknown verbs.</summary>
        public int HomonymCount(string verb) => Math.Max(1, HomonymIndices(verb).Count);
        private VerbEntry? Metadata(string verb, int? homonym = null, bool resolve = false) {
            string key = verb.Normalize(NormalizationForm.FormC);
            if (resolve)
                key = catalogue.Resolve(key, homonym);
            return catalogue.Entries.TryGetValue(key, out var entry) ? entry.Metadata : null;
        }
        /// <summary>Whether the exact catalogue key has an aspirated initial h.</summary>
        public bool IsHAspire(string verb) => Metadata(verb)?.IsHAspire ?? false;
        /// <summary>Lexical blocking for the resolved entry; auxiliaries may still elide.</summary>
        public bool BlocksElisionAndLiaison(string verb, int? homonymIndex = null) => Metadata(verb, homonymIndex, true)?.BlocksElisionAndLiaison ?? false;
        /// <summary>Whether the exact key is marked as a reform variant.</summary>
        public bool Is1990Reform(string verb) => Metadata(verb)?.Is1990Reform ?? false;
        /// <summary>Reform variant of the exact key, or null when absent.</summary>
        public string? ReformVariant(string verb) => Metadata(verb)?.Variant;
        private static string SortKey(string value) => new string(value.Replace("œ", "oe").Replace("æ", "ae").Normalize(NormalizationForm.FormKD).Where(c => CharUnicodeInfo.GetUnicodeCategory(c) != UnicodeCategory.NonSpacingMark).ToArray());
        private static string Slot(Voice voice, Mode mode, Tense tense, Person person) => $"{voice.Label()}|{mode.Label()}|{tense.Label()}|{person.Label()}";
        private string? TypedForm(string verb, Voice voice, Mode mode, Tense tense, Person person, int? homonym, Prediction prediction) => Form(verb, Slot(voice, mode, tense, person), prediction, homonym);
        private Dictionary<Person, string> TypedPersons(string verb, Voice voice, Mode mode, Tense tense, int? homonym, Prediction prediction) {
            var result = new Dictionary<Person, string>();
            foreach (Person person in Enum.GetValues(typeof(Person))) {
                var value = TypedForm(verb, voice, mode, tense, person, homonym, prediction);
                if (value != null)
                    result.Add(person, value);
            }
            return result;
        }
        private Dictionary<Tense, Dictionary<Person, string>> TypedTenses(string verb, Voice voice, Mode mode, int? homonym, Prediction prediction) {
            var result = new Dictionary<Tense, Dictionary<Person, string>>();
            foreach (Tense tense in Enum.GetValues(typeof(Tense))) {
                var value = TypedPersons(verb, voice, mode, tense, homonym, prediction);
                if (value.Count != 0)
                    result.Add(tense, value);
            }
            return result;
        }
        private Dictionary<Mode, Dictionary<Tense, Dictionary<Person, string>>> TypedModes(string verb, Voice voice, int? homonym, Prediction prediction) {
            var result = new Dictionary<Mode, Dictionary<Tense, Dictionary<Person, string>>>();
            foreach (Mode mode in Enum.GetValues(typeof(Mode))) {
                if (mode == Mode.Participe)
                    continue;
                var value = TypedTenses(verb, voice, mode, homonym, prediction);
                if (value.Count != 0)
                    result.Add(mode, value);
            }
            return result;
        }
        private Dictionary<Voice, Dictionary<Mode, Dictionary<Tense, Dictionary<Person, string>>>>? TypedVoices(string verb, int? homonym, Prediction prediction) {
            var result = new Dictionary<Voice, Dictionary<Mode, Dictionary<Tense, Dictionary<Person, string>>>>();
            foreach (Voice voice in Enum.GetValues(typeof(Voice))) {
                var value = TypedModes(verb, voice, homonym, prediction);
                if (value.Count != 0)
                    result.Add(voice, value);
            }
            return result.Count == 0 ? null : result;
        }
        /// <summary>Catalogue finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested.</summary>
        public Dictionary<Voice, Dictionary<Mode, Dictionary<Tense, Dictionary<Person, string>>>>? Conjugate(string verb, int? homonymIndex = null) => TypedVoices(verb, homonymIndex, Prediction.Catalogue);
        /// <summary>Catalogue finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested.</summary>
        public Dictionary<Mode, Dictionary<Tense, Dictionary<Person, string>>> Conjugate(string verb, Voice voice, int? homonymIndex = null) => TypedModes(verb, voice, homonymIndex, Prediction.Catalogue);
        /// <summary>Catalogue finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested.</summary>
        public Dictionary<Tense, Dictionary<Person, string>> Conjugate(string verb, Voice voice, Mode mode, int? homonymIndex = null) => TypedTenses(verb, voice, mode, homonymIndex, Prediction.Catalogue);
        /// <summary>Catalogue finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested.</summary>
        public Dictionary<Person, string> Conjugate(string verb, Voice voice, Mode mode, Tense tense, int? homonymIndex = null) => TypedPersons(verb, voice, mode, tense, homonymIndex, Prediction.Catalogue);
        /// <summary>Catalogue finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested.</summary>
        public string? Conjugate(string verb, Voice voice, Mode mode, Tense tense, Person person, int? homonymIndex = null) => TypedForm(verb, voice, mode, tense, person, homonymIndex, Prediction.Catalogue);
        /// <summary>Inferred finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested.</summary>
        public Dictionary<Voice, Dictionary<Mode, Dictionary<Tense, Dictionary<Person, string>>>>? RawInferredConjugation(string verb, int? homonymIndex = null) => TypedVoices(verb, homonymIndex, Prediction.Inferred);
        /// <summary>Inferred finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested.</summary>
        public Dictionary<Mode, Dictionary<Tense, Dictionary<Person, string>>> RawInferredConjugation(string verb, Voice voice, int? homonymIndex = null) => TypedModes(verb, voice, homonymIndex, Prediction.Inferred);
        /// <summary>Inferred finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested.</summary>
        public Dictionary<Tense, Dictionary<Person, string>> RawInferredConjugation(string verb, Voice voice, Mode mode, int? homonymIndex = null) => TypedTenses(verb, voice, mode, homonymIndex, Prediction.Inferred);
        /// <summary>Inferred finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested.</summary>
        public Dictionary<Person, string> RawInferredConjugation(string verb, Voice voice, Mode mode, Tense tense, int? homonymIndex = null) => TypedPersons(verb, voice, mode, tense, homonymIndex, Prediction.Inferred);
        /// <summary>Inferred finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested.</summary>
        public string? RawInferredConjugation(string verb, Voice voice, Mode mode, Tense tense, Person person, int? homonymIndex = null) => TypedForm(verb, voice, mode, tense, person, homonymIndex, Prediction.Inferred);
        /// <summary>Guess finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested.</summary>
        public Dictionary<Voice, Dictionary<Mode, Dictionary<Tense, Dictionary<Person, string>>>>? GuessConjugation(string verb, int? homonymIndex = null) => TypedVoices(verb, homonymIndex, Prediction.Guess);
        /// <summary>Guess finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested.</summary>
        public Dictionary<Mode, Dictionary<Tense, Dictionary<Person, string>>> GuessConjugation(string verb, Voice voice, int? homonymIndex = null) => TypedModes(verb, voice, homonymIndex, Prediction.Guess);
        /// <summary>Guess finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested.</summary>
        public Dictionary<Tense, Dictionary<Person, string>> GuessConjugation(string verb, Voice voice, Mode mode, int? homonymIndex = null) => TypedTenses(verb, voice, mode, homonymIndex, Prediction.Guess);
        /// <summary>Guess finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested.</summary>
        public Dictionary<Person, string> GuessConjugation(string verb, Voice voice, Mode mode, Tense tense, int? homonymIndex = null) => TypedPersons(verb, voice, mode, tense, homonymIndex, Prediction.Guess);
        /// <summary>Guess finite forms. Missing single/all-voice output is null; scoped maps omit missing forms. Predictions may be unattested.</summary>
        public string? GuessConjugation(string verb, Voice voice, Mode mode, Tense tense, Person person, int? homonymIndex = null) => TypedForm(verb, voice, mode, tense, person, homonymIndex, Prediction.Guess);
        /// <summary>Catalogue participle selected by gendered tense, or null if unsupported.</summary>
        public string? Participle(string verb, Voice voice, Tense tense, int? homonymIndex = null) => Form(verb, $"{voice.Label()}|participe|{tense.Label()}|-", Prediction.Catalogue, homonymIndex);
        /// <summary>All catalogue participles keyed by typed tense; missing values omitted.</summary>
        public Dictionary<Tense, string> Participles(string verb, Voice voice, int? homonymIndex = null) => ((Tense[])Enum.GetValues(typeof(Tense))).Select(t => (t, value: Participle(verb, voice, t, homonymIndex))).Where(x => x.value != null).ToDictionary(x => x.t, x => x.value!);
        /// <summary>Catalogue gérondif. Each inferred alternative receives en; unsupported tenses return null.</summary>
        public string? Gerondif(string verb, Voice voice, Tense tense, int? homonymIndex = null) => Gerondif(verb, voice.Label(), tense.Label(), Prediction.Catalogue, homonymIndex);
        /// <summary>Inferred participle selected by gendered tense, or null if unsupported.</summary>
        public string? RawInferredParticiple(string verb, Voice voice, Tense tense, int? homonymIndex = null) => Form(verb, $"{voice.Label()}|participe|{tense.Label()}|-", Prediction.Inferred, homonymIndex);
        /// <summary>All inferred participles keyed by typed tense; missing values omitted.</summary>
        public Dictionary<Tense, string> RawInferredParticiples(string verb, Voice voice, int? homonymIndex = null) => ((Tense[])Enum.GetValues(typeof(Tense))).Select(t => (t, value: RawInferredParticiple(verb, voice, t, homonymIndex))).Where(x => x.value != null).ToDictionary(x => x.t, x => x.value!);
        /// <summary>Inferred gérondif. Each inferred alternative receives en; unsupported tenses return null.</summary>
        public string? RawInferredGerondif(string verb, Voice voice, Tense tense, int? homonymIndex = null) => Gerondif(verb, voice.Label(), tense.Label(), Prediction.Inferred, homonymIndex);
        /// <summary>Guess participle selected by gendered tense, or null if unsupported.</summary>
        public string? GuessParticiple(string verb, Voice voice, Tense tense, int? homonymIndex = null) => Form(verb, $"{voice.Label()}|participe|{tense.Label()}|-", Prediction.Guess, homonymIndex);
        /// <summary>All guess participles keyed by typed tense; missing values omitted.</summary>
        public Dictionary<Tense, string> GuessParticiples(string verb, Voice voice, int? homonymIndex = null) => ((Tense[])Enum.GetValues(typeof(Tense))).Select(t => (t, value: GuessParticiple(verb, voice, t, homonymIndex))).Where(x => x.value != null).ToDictionary(x => x.t, x => x.value!);
        /// <summary>Guess gérondif. Each inferred alternative receives en; unsupported tenses return null.</summary>
        public string? GuessGerondif(string verb, Voice voice, Tense tense, int? homonymIndex = null) => Gerondif(verb, voice.Label(), tense.Label(), Prediction.Guess, homonymIndex);
        /// <summary>Typed catalogue query. Alternatives fall back to primary; absent forms return null (false for availability).</summary>
        public string? ConjugateAlternative(string verb, Voice voice, Mode mode, Tense tense, Person person, int? homonymIndex = null) => Form(verb, Slot(voice, mode, tense, person), homonymIndex: homonymIndex, spelling: Spelling.Alternative);
        /// <summary>Typed catalogue query. Alternatives fall back to primary; absent forms return null (false for availability).</summary>
        public bool HasAlternativeForm(string verb, Voice voice, Mode mode, Tense tense, Person person, int? homonymIndex = null) => Form(verb, Slot(voice, mode, tense, person), homonymIndex: homonymIndex, spelling: Spelling.All)?.Contains(";") ?? false;
        /// <summary>Typed catalogue query. Alternatives fall back to primary; absent forms return null (false for availability).</summary>
        public string? GetPronoun(string verb, Voice voice, Mode mode, Tense tense, Person person, int? homonymIndex = null) => Pronoun(verb, Slot(voice, mode, tense, person), homonymIndex, Spelling.Primary);
        /// <summary>Typed catalogue query. Alternatives fall back to primary; absent forms return null (false for availability).</summary>
        public string? ConjugateWithPronoun(string verb, Voice voice, Mode mode, Tense tense, Person person, int? homonymIndex = null) => WithPronoun(verb, Slot(voice, mode, tense, person), homonymIndex, Spelling.Primary);
        /// <summary>Typed catalogue query. Alternatives fall back to primary; absent forms return null (false for availability).</summary>
        public string? ConjugateAlternativeWithPronoun(string verb, Voice voice, Mode mode, Tense tense, Person person, int? homonymIndex = null) => WithPronoun(verb, Slot(voice, mode, tense, person), homonymIndex, Spelling.Alternative);
        /// <summary>Catalogue participle alternative or alternative availability; unsupported tenses are missing.</summary>
        public string? ParticipleAlternative(string verb, Voice voice, Tense tense, int? homonymIndex = null) => Form(verb, $"{voice.Label()}|participe|{tense.Label()}|-", homonymIndex: homonymIndex, spelling: Spelling.Alternative);
        /// <summary>Catalogue participle alternative or alternative availability; unsupported tenses are missing.</summary>
        public bool HasAlternativeParticiple(string verb, Voice voice, Tense tense, int? homonymIndex = null) => Form(verb, $"{voice.Label()}|participe|{tense.Label()}|-", homonymIndex: homonymIndex, spelling: Spelling.All)?.Contains(";") ?? false;
        /// <summary>Catalogue structure with at least one available form, ordered by raw label.</summary>
        public IReadOnlyList<Voice> Voices(string verb, int? homonymIndex = null) => Forms(verb, homonymIndex: homonymIndex).Keys.Select(s => s.Split('|')).Where(p => true).Select(p => (Voice)Array.Find(Enum.GetValues(typeof(Voice)).Cast<Voice>().ToArray(), x => x.Label() == p[0])).Distinct().OrderBy(x => x.Label(), StringComparer.Ordinal).ToArray();
        /// <summary>Catalogue structure with at least one available form, ordered by raw label.</summary>
        public IReadOnlyList<Mode> Modes(string verb, Voice voice, int? homonymIndex = null) => Forms(verb, homonymIndex: homonymIndex).Keys.Select(s => s.Split('|')).Where(p => p[0] == voice.Label()).Select(p => (Mode)Array.Find(Enum.GetValues(typeof(Mode)).Cast<Mode>().ToArray(), x => x.Label() == p[1])).Distinct().OrderBy(x => x.Label(), StringComparer.Ordinal).ToArray();
        /// <summary>Catalogue structure with at least one available form, ordered by raw label.</summary>
        public IReadOnlyList<Tense> Tenses(string verb, Voice voice, Mode mode, int? homonymIndex = null) => Forms(verb, homonymIndex: homonymIndex).Keys.Select(s => s.Split('|')).Where(p => p[0] == voice.Label() && p[1] == mode.Label()).Select(p => (Tense)Array.Find(Enum.GetValues(typeof(Tense)).Cast<Tense>().ToArray(), x => x.Label() == p[2])).Distinct().OrderBy(x => x.Label(), StringComparer.Ordinal).ToArray();
        /// <summary>Persons grouped by identical full spellings in declaration order; no participles.</summary>
        public IReadOnlyList<Person> Persons(string verb, Voice voice, Mode mode, Tense tense, int? homonymIndex = null) {
            var groups = new Dictionary<string, List<Person>>();
            var order = new List<string>();
            if (mode == Mode.Participe)
                return Array.Empty<Person>();
            foreach (Person person in Enum.GetValues(typeof(Person))) {
                var raw = Form(verb, Slot(voice, mode, tense, person), homonymIndex: homonymIndex, spelling: Spelling.All);
                if (raw == null)
                    continue;
                if (!groups.TryGetValue(raw, out var values)) {
                    values = new List<Person>();
                    groups.Add(raw, values);
                    order.Add(raw);
                }
                values.Add(person);
            }
            return order.SelectMany(raw => groups[raw]).ToArray();
        }
    }
}
