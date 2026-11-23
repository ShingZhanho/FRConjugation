using System.Threading.Tasks;
using System.Collections.Generic;
namespace ShingZhanho.FRConjugation {
    public sealed partial class Conjugator {
        /// <summary>Run Conjugate off the calling thread. Work is not cancellable.</summary>
        public Task<Dictionary<Voice, Dictionary<Mode, Dictionary<Tense, Dictionary<Person, string>>>>?> ConjugateAsync(string verb, int? homonymIndex = null) => Task.Run(() => Conjugate(verb, homonymIndex));
        /// <summary>Run Conjugate off the calling thread. Work is not cancellable.</summary>
        public Task<Dictionary<Mode, Dictionary<Tense, Dictionary<Person, string>>>> ConjugateAsync(string verb, Voice voice, int? homonymIndex = null) => Task.Run(() => Conjugate(verb, voice, homonymIndex));
        /// <summary>Run Conjugate off the calling thread. Work is not cancellable.</summary>
        public Task<Dictionary<Tense, Dictionary<Person, string>>> ConjugateAsync(string verb, Voice voice, Mode mode, int? homonymIndex = null) => Task.Run(() => Conjugate(verb, voice, mode, homonymIndex));
        /// <summary>Run Conjugate off the calling thread. Work is not cancellable.</summary>
        public Task<Dictionary<Person, string>> ConjugateAsync(string verb, Voice voice, Mode mode, Tense tense, int? homonymIndex = null) => Task.Run(() => Conjugate(verb, voice, mode, tense, homonymIndex));
        /// <summary>Run Conjugate off the calling thread. Work is not cancellable.</summary>
        public Task<string?> ConjugateAsync(string verb, Voice voice, Mode mode, Tense tense, Person person, int? homonymIndex = null) => Task.Run(() => Conjugate(verb, voice, mode, tense, person, homonymIndex));
        /// <summary>Run RawInferredConjugation off the calling thread. Work is not cancellable.</summary>
        public Task<Dictionary<Voice, Dictionary<Mode, Dictionary<Tense, Dictionary<Person, string>>>>?> RawInferredConjugationAsync(string verb, int? homonymIndex = null) => Task.Run(() => RawInferredConjugation(verb, homonymIndex));
        /// <summary>Run RawInferredConjugation off the calling thread. Work is not cancellable.</summary>
        public Task<Dictionary<Mode, Dictionary<Tense, Dictionary<Person, string>>>> RawInferredConjugationAsync(string verb, Voice voice, int? homonymIndex = null) => Task.Run(() => RawInferredConjugation(verb, voice, homonymIndex));
        /// <summary>Run RawInferredConjugation off the calling thread. Work is not cancellable.</summary>
        public Task<Dictionary<Tense, Dictionary<Person, string>>> RawInferredConjugationAsync(string verb, Voice voice, Mode mode, int? homonymIndex = null) => Task.Run(() => RawInferredConjugation(verb, voice, mode, homonymIndex));
        /// <summary>Run RawInferredConjugation off the calling thread. Work is not cancellable.</summary>
        public Task<Dictionary<Person, string>> RawInferredConjugationAsync(string verb, Voice voice, Mode mode, Tense tense, int? homonymIndex = null) => Task.Run(() => RawInferredConjugation(verb, voice, mode, tense, homonymIndex));
        /// <summary>Run RawInferredConjugation off the calling thread. Work is not cancellable.</summary>
        public Task<string?> RawInferredConjugationAsync(string verb, Voice voice, Mode mode, Tense tense, Person person, int? homonymIndex = null) => Task.Run(() => RawInferredConjugation(verb, voice, mode, tense, person, homonymIndex));
        /// <summary>Run GuessConjugation off the calling thread. Work is not cancellable.</summary>
        public Task<Dictionary<Voice, Dictionary<Mode, Dictionary<Tense, Dictionary<Person, string>>>>?> GuessConjugationAsync(string verb, int? homonymIndex = null) => Task.Run(() => GuessConjugation(verb, homonymIndex));
        /// <summary>Run GuessConjugation off the calling thread. Work is not cancellable.</summary>
        public Task<Dictionary<Mode, Dictionary<Tense, Dictionary<Person, string>>>> GuessConjugationAsync(string verb, Voice voice, int? homonymIndex = null) => Task.Run(() => GuessConjugation(verb, voice, homonymIndex));
        /// <summary>Run GuessConjugation off the calling thread. Work is not cancellable.</summary>
        public Task<Dictionary<Tense, Dictionary<Person, string>>> GuessConjugationAsync(string verb, Voice voice, Mode mode, int? homonymIndex = null) => Task.Run(() => GuessConjugation(verb, voice, mode, homonymIndex));
        /// <summary>Run GuessConjugation off the calling thread. Work is not cancellable.</summary>
        public Task<Dictionary<Person, string>> GuessConjugationAsync(string verb, Voice voice, Mode mode, Tense tense, int? homonymIndex = null) => Task.Run(() => GuessConjugation(verb, voice, mode, tense, homonymIndex));
        /// <summary>Run GuessConjugation off the calling thread. Work is not cancellable.</summary>
        public Task<string?> GuessConjugationAsync(string verb, Voice voice, Mode mode, Tense tense, Person person, int? homonymIndex = null) => Task.Run(() => GuessConjugation(verb, voice, mode, tense, person, homonymIndex));
        /// <summary>Run Participle off the calling thread. Work is not cancellable.</summary>
        public Task<string?> ParticipleAsync(string verb, Voice voice, Tense tense, int? homonymIndex = null) => Task.Run(() => Participle(verb, voice, tense, homonymIndex));
        /// <summary>Run Gerondif off the calling thread. Work is not cancellable.</summary>
        public Task<string?> GerondifAsync(string verb, Voice voice, Tense tense, int? homonymIndex = null) => Task.Run(() => Gerondif(verb, voice, tense, homonymIndex));
        /// <summary>Run RawInferredParticiple off the calling thread. Work is not cancellable.</summary>
        public Task<string?> RawInferredParticipleAsync(string verb, Voice voice, Tense tense, int? homonymIndex = null) => Task.Run(() => RawInferredParticiple(verb, voice, tense, homonymIndex));
        /// <summary>Run RawInferredGerondif off the calling thread. Work is not cancellable.</summary>
        public Task<string?> RawInferredGerondifAsync(string verb, Voice voice, Tense tense, int? homonymIndex = null) => Task.Run(() => RawInferredGerondif(verb, voice, tense, homonymIndex));
        /// <summary>Run GuessParticiple off the calling thread. Work is not cancellable.</summary>
        public Task<string?> GuessParticipleAsync(string verb, Voice voice, Tense tense, int? homonymIndex = null) => Task.Run(() => GuessParticiple(verb, voice, tense, homonymIndex));
        /// <summary>Run GuessGerondif off the calling thread. Work is not cancellable.</summary>
        public Task<string?> GuessGerondifAsync(string verb, Voice voice, Tense tense, int? homonymIndex = null) => Task.Run(() => GuessGerondif(verb, voice, tense, homonymIndex));
        /// <summary>Run ConjugateAlternative off the calling thread. Work is not cancellable.</summary>
        public Task<string?> ConjugateAlternativeAsync(string verb, Voice voice, Mode mode, Tense tense, Person person, int? homonymIndex = null) => Task.Run(() => ConjugateAlternative(verb, voice, mode, tense, person, homonymIndex));
        /// <summary>Run GetPronoun off the calling thread. Work is not cancellable.</summary>
        public Task<string?> GetPronounAsync(string verb, Voice voice, Mode mode, Tense tense, Person person, int? homonymIndex = null) => Task.Run(() => GetPronoun(verb, voice, mode, tense, person, homonymIndex));
        /// <summary>Run ConjugateWithPronoun off the calling thread. Work is not cancellable.</summary>
        public Task<string?> ConjugateWithPronounAsync(string verb, Voice voice, Mode mode, Tense tense, Person person, int? homonymIndex = null) => Task.Run(() => ConjugateWithPronoun(verb, voice, mode, tense, person, homonymIndex));
        /// <summary>Run ConjugateAlternativeWithPronoun off the calling thread. Work is not cancellable.</summary>
        public Task<string?> ConjugateAlternativeWithPronounAsync(string verb, Voice voice, Mode mode, Tense tense, Person person, int? homonymIndex = null) => Task.Run(() => ConjugateAlternativeWithPronoun(verb, voice, mode, tense, person, homonymIndex));
        /// <summary>Run ParticipleAlternative off the calling thread. Work is not cancellable.</summary>
        public Task<string?> ParticipleAlternativeAsync(string verb, Voice voice, Tense tense, int? homonymIndex = null) => Task.Run(() => ParticipleAlternative(verb, voice, tense, homonymIndex));
        /// <summary>Run CommonPrefix off the calling thread; work is not cancellable.</summary>
        public Task<string?> CommonPrefixAsync(string verb, int? homonymIndex = null) => Task.Run(() => CommonPrefix(verb, homonymIndex));
        /// <summary>Run RawInferredCommonPrefix off the calling thread; work is not cancellable.</summary>
        public Task<string?> RawInferredCommonPrefixAsync(string verb, int? homonymIndex = null) => Task.Run(() => RawInferredCommonPrefix(verb, homonymIndex));
        /// <summary>Run GuessCommonPrefix off the calling thread; work is not cancellable.</summary>
        public Task<string?> GuessCommonPrefixAsync(string verb, int? homonymIndex = null) => Task.Run(() => GuessCommonPrefix(verb, homonymIndex));
        /// <summary>Load a new bundled reader off the calling thread.</summary>
        public static Task<Conjugator> LoadAsync() => Task.Run(() => new Conjugator());
        /// <summary>Obtain the shared reader off the calling thread.</summary>
        public static Task<Conjugator> GetSharedAsync() => Task.Run(GetShared);
    }
}
