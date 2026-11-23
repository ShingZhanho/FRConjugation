#ifndef FRCONJUGATION_HPP
#define FRCONJUGATION_HPP
#include "frconjugation_api.h"
#include "frconjugation_types.hpp"
#include <map>
#include <future>
#include <type_traits>
#include <memory>
#include <optional>
#include <stdexcept>
#include <string>
#include <vector>

/** RAII wrappers for the bundled C API. */
namespace frconjugation {
/** Failure to load the bundled catalogue. */
class ConjugationError : public std::runtime_error {
  public:
    /** Construct a resource-loading error description. */
    explicit ConjugationError(const std::string &message) : std::runtime_error(message) {}
};
/** Person-to-form map. */
using PersonForms = std::map<Person, std::string>;
/** Tense-to-person-map result. */
using TenseForms = std::map<Tense, PersonForms>;
/** Mood-to-tense-map result. */
using ModeForms = std::map<Mode, TenseForms>;
/** Voice-to-mood-map result. */
using VoiceForms = std::map<Voice, ModeForms>;
/** Move-only bundled reader with concurrent const queries. UTF-8 inputs must not
 * contain embedded NUL bytes. Missing output is nullopt; invalid requests throw
 * invalid_argument and internal failures throw runtime_error. Loading throws
 * ConjugationError. Moved-from readers must be reassigned before querying.
 * Async futures retain the engine independently of this object's lifetime.
 * Destruction of the last unconsumed std::async future may block until work ends.
 */
class Conjugator {
    std::shared_ptr<frc_engine> engine_;
    explicit Conjugator(std::shared_ptr<frc_engine> engine) : engine_(std::move(engine)) {}
    using Response = std::unique_ptr<frc_response, decltype(&frc_response_free)>;
    Response query(const frc_request &request) const {
        frc_response *response = nullptr;
        auto status = frc_query(engine_.get(), &request, &response);
        Response owner(response, frc_response_free);
        if (status == FRC_MISSING)
            return owner;
        if (status == FRC_INVALID_ARGUMENT)
            throw std::invalid_argument("Invalid typed query");
        if (status != FRC_OK)
            throw std::runtime_error("Typed query failed");
        return owner;
    }
    static frc_request request(frc_operation operation, const std::string &verb, int homonym = 0,
                               frc_mode prediction = FRC_CATALOGUE) {
        auto q = frc_request_init(operation, verb.c_str());
        q.homonym = homonym;
        q.prediction = prediction;
        return q;
    }
    static std::optional<std::string> text(const Response &r) {
        auto p = frc_response_text(r.get());
        return p ? std::optional<std::string>(p) : std::optional<std::string>();
    }
    template <class F>
    auto background(F function) const -> std::future<std::invoke_result_t<F, const Conjugator &>> {
        return std::async(std::launch::async, [owner = engine_, function]() {
            Conjugator reader(owner);
            return function(reader);
        });
    }
    static std::optional<std::string> result(frc_status status, char *text) {
        std::unique_ptr<char, decltype(&frc_string_free)> owner(text, frc_string_free);
        if (status == FRC_MISSING)
            return std::nullopt;
        if (status == FRC_INVALID_ARGUMENT)
            throw std::invalid_argument("Invalid conjugation argument");
        if (status != FRC_OK)
            throw std::runtime_error("Conjugation operation failed");
        return std::string(text);
    }

  public:
    /** Load the bundled catalogue; throws std::runtime_error if loading fails. */
    Conjugator() {
        frc_engine *value = nullptr;
        if (frc_create(&value) != FRC_OK)
            throw ConjugationError("Cannot load bundled catalogue");
        engine_.reset(value, frc_destroy);
    }
    /** Transfer catalogue ownership; the source becomes empty. */
    Conjugator(Conjugator &&) noexcept = default;
    /** Release this catalogue and take ownership of the source catalogue. */
    Conjugator &operator=(Conjugator &&) noexcept = default;
    /** Borrow the C handle. It remains valid until destruction, move or assignment; do not free it.
     */
    const frc_engine *native_handle() const noexcept {
        return engine_.get();
    }
    /** Query a slot (voice|mode|tense|person); see frc_form for normalization and spelling
     * semantics. homonym = 0 selects the first indexed entry. Missing forms return std::nullopt. */
    std::optional<std::string> form(const std::string &verb, const std::string &slot,
                                    frc_mode mode = FRC_CATALOGUE, int homonym = 0,
                                    frc_spelling spelling = FRC_PRIMARY) const {
        char *text = nullptr;
        auto status =
            frc_form(engine_.get(), verb.c_str(), slot.c_str(), homonym, mode, spelling, &text);
        return result(status, text);
    }
    /** Shared spelling across all forms and alternatives, excluding auxiliaries and pronouns.
     * Empty is a valid prefix; std::nullopt means no forms. See frc_common_prefix. */
    std::optional<std::string> common_prefix(const std::string &verb, frc_mode mode = FRC_CATALOGUE,
                                             int homonym = 0) const {
        char *text = nullptr;
        auto status = frc_common_prefix(engine_.get(), verb.c_str(), homonym, mode, &text);
        return result(status, text);
    }
    /** Derive gerondif_present or gerondif_passe_sm/sf/pm/pf in the given voice.
     * Missing participles return std::nullopt. See frc_gerondif for prediction semantics. */
    std::optional<std::string> gerondif(const std::string &verb, const std::string &voice,
                                        const std::string &tense, frc_mode mode = FRC_CATALOGUE,
                                        int homonym = 0) const {
        char *text = nullptr;
        auto status = frc_gerondif(engine_.get(), verb.c_str(), voice.c_str(), tense.c_str(),
                                   homonym, mode, &text);
        return result(status, text);
    }
    /** Catalogue form with subject/elision, or bare imperative/participle.
     * FRC_ALL is invalid; absent forms return std::nullopt. See frc_with_pronoun. */
    std::optional<std::string> with_pronoun(const std::string &verb, const std::string &slot,
                                            int homonym = 0,
                                            frc_spelling spelling = FRC_PRIMARY) const {
        char *text = nullptr;
        auto status =
            frc_with_pronoun(engine_.get(), verb.c_str(), slot.c_str(), homonym, spelling, &text);
        return result(status, text);
    }
    /** Return all supported slot labels in catalogue order, including participles. */
    std::vector<std::string> slots() const {
        std::vector<std::string> values;
        for (size_t i = 0; i < frc_slot_count(engine_.get()); ++i) {
            char *text = nullptr;
            auto status = frc_slot_name(engine_.get(), i, &text);
            values.push_back(*result(status, text));
        }
        return values;
    }
    /** Return the shared bundled reader. Callers must not move from it. */
    static const Conjugator &get_shared() {
        static const Conjugator reader;
        return reader;
    }
    /** Construct a new reader on a worker thread; future owns the result. */
    static std::future<Conjugator> load_async() {
        return std::async(std::launch::async, [] { return Conjugator(); });
    }
    /** Acquire the shared reader on a worker thread. */
    static std::future<std::reference_wrapper<const Conjugator>> get_shared_async() {
        return std::async(std::launch::async, [] { return std::cref(get_shared()); });
    }
    /** All base infinitives in French-oriented order. */
    std::vector<std::string> all_verbs() const {
        auto r = query(request(FRC_QUERY_ALL_VERBS, ""));
        std::vector<std::string> values;
        for (size_t i = 0; i < frc_response_string_count(r.get()); ++i)
            values.emplace_back(frc_response_string(r.get(), i));
        return values;
    }
    /** Catalogue verb count query; absent flags are false, default homonym count is one. */
    size_t verb_count() const {
        auto r = query(request(FRC_QUERY_VERB_COUNT, ""));
        return frc_response_number(r.get());
    }
    /** Catalogue has verb query; absent flags are false, default homonym count is one. */
    bool has_verb(const std::string &verb) const {
        auto r = query(request(FRC_QUERY_HAS_VERB, verb));
        return frc_response_number(r.get());
    }
    /** Catalogue has homonyms query; absent flags are false, default homonym count is one. */
    bool has_homonyms(const std::string &verb) const {
        auto r = query(request(FRC_QUERY_HAS_HOMONYMS, verb));
        return frc_response_number(r.get());
    }
    /** Catalogue homonym count query; absent flags are false, default homonym count is one. */
    size_t homonym_count(const std::string &verb) const {
        auto r = query(request(FRC_QUERY_HOMONYM_COUNT, verb));
        return frc_response_number(r.get());
    }
    /** Catalogue is h aspire query; absent flags are false, default homonym count is one. */
    bool is_h_aspire(const std::string &verb) const {
        auto r = query(request(FRC_QUERY_IS_H_ASPIRE, verb));
        return frc_response_number(r.get());
    }
    /** Catalogue is 1990 reform query; absent flags are false, default homonym count is one. */
    bool is_1990_reform(const std::string &verb) const {
        auto r = query(request(FRC_QUERY_IS_1990_REFORM, verb));
        return frc_response_number(r.get());
    }
    /** Catalogue blocks elision and liaison query; absent flags are false, default homonym count is
     * one. */
    bool blocks_elision_and_liaison(const std::string &verb, int homonym = 0) const {
        auto r = query(request(FRC_QUERY_BLOCKS_ELISION, verb, homonym));
        return frc_response_number(r.get());
    }
    /** Reform variant for the exact entry, or nullopt. */
    std::optional<std::string> reform_variant(const std::string &verb) const {
        return text(query(request(FRC_QUERY_REFORM_VARIANT, verb)));
    }
    /** Ascending homonym indices for a base infinitive. */
    std::vector<int> homonym_indices(const std::string &verb) const {
        auto r = query(request(FRC_QUERY_HOMONYM_INDICES, verb));
        std::vector<int> result;
        for (size_t i = 0; i < frc_response_value_count(r.get()); ++i)
            result.push_back(frc_response_value(r.get(), i));
        return result;
    }
    /** Typed finite forms. Scoped bulk results omit missing forms; all-voice and single missing
     * output is nullopt. */
    std::optional<VoiceForms> conjugate(const std::string &verb, int homonym = 0) const {
        auto q = request(FRC_QUERY_CONJUGATE, verb, homonym, FRC_CATALOGUE);
        auto r = query(q);
        if (!r)
            return {};
        VoiceForms result;
        for (size_t i = 0; i < frc_response_row_count(r.get()); ++i) {
            auto row = frc_response_row(r.get(), i);
            result[static_cast<Voice>(row->voice)][static_cast<Mode>(row->mood)]
                  [static_cast<Tense>(row->tense)][static_cast<Person>(row->person)] = row->text;
        }
        return result;
    }
    /** Run conjugate on a worker; retains the engine even after this reader is destroyed. */
    std::future<std::optional<VoiceForms>> conjugate_async(const std::string &verb,
                                                           int homonym = 0) const {
        return background([=](const Conjugator &c) { return c.conjugate(verb, homonym); });
    }
    /** Typed finite forms. Scoped bulk results omit missing forms; all-voice and single missing
     * output is nullopt. */
    ModeForms conjugate(const std::string &verb, Voice voice, int homonym = 0) const {
        auto q = request(FRC_QUERY_CONJUGATE, verb, homonym, FRC_CATALOGUE);
        q.voice = static_cast<frc_voice>(voice);
        auto r = query(q);
        ModeForms result;
        for (size_t i = 0; i < frc_response_row_count(r.get()); ++i) {
            auto row = frc_response_row(r.get(), i);
            result[static_cast<Mode>(row->mood)][static_cast<Tense>(row->tense)]
                  [static_cast<Person>(row->person)] = row->text;
        }
        return result;
    }
    /** Run conjugate on a worker; retains the engine even after this reader is destroyed. */
    std::future<ModeForms> conjugate_async(const std::string &verb, Voice voice,
                                           int homonym = 0) const {
        return background([=](const Conjugator &c) { return c.conjugate(verb, voice, homonym); });
    }
    /** Typed finite forms. Scoped bulk results omit missing forms; all-voice and single missing
     * output is nullopt. */
    TenseForms conjugate(const std::string &verb, Voice voice, Mode mode, int homonym = 0) const {
        auto q = request(FRC_QUERY_CONJUGATE, verb, homonym, FRC_CATALOGUE);
        q.voice = static_cast<frc_voice>(voice);
        q.mood = static_cast<frc_mood>(mode);
        auto r = query(q);
        TenseForms result;
        for (size_t i = 0; i < frc_response_row_count(r.get()); ++i) {
            auto row = frc_response_row(r.get(), i);
            result[static_cast<Tense>(row->tense)][static_cast<Person>(row->person)] = row->text;
        }
        return result;
    }
    /** Run conjugate on a worker; retains the engine even after this reader is destroyed. */
    std::future<TenseForms> conjugate_async(const std::string &verb, Voice voice, Mode mode,
                                            int homonym = 0) const {
        return background(
            [=](const Conjugator &c) { return c.conjugate(verb, voice, mode, homonym); });
    }
    /** Typed finite forms. Scoped bulk results omit missing forms; all-voice and single missing
     * output is nullopt. */
    PersonForms conjugate(const std::string &verb, Voice voice, Mode mode, Tense tense,
                          int homonym = 0) const {
        auto q = request(FRC_QUERY_CONJUGATE, verb, homonym, FRC_CATALOGUE);
        q.voice = static_cast<frc_voice>(voice);
        q.mood = static_cast<frc_mood>(mode);
        q.tense = static_cast<frc_tense>(tense);
        auto r = query(q);
        PersonForms result;
        for (size_t i = 0; i < frc_response_row_count(r.get()); ++i) {
            auto row = frc_response_row(r.get(), i);
            result[static_cast<Person>(row->person)] = row->text;
        }
        return result;
    }
    /** Run conjugate on a worker; retains the engine even after this reader is destroyed. */
    std::future<PersonForms> conjugate_async(const std::string &verb, Voice voice, Mode mode,
                                             Tense tense, int homonym = 0) const {
        return background(
            [=](const Conjugator &c) { return c.conjugate(verb, voice, mode, tense, homonym); });
    }
    /** Typed finite forms. Scoped bulk results omit missing forms; all-voice and single missing
     * output is nullopt. */
    std::optional<std::string> conjugate(const std::string &verb, Voice voice, Mode mode,
                                         Tense tense, Person person, int homonym = 0) const {
        auto q = request(FRC_QUERY_CONJUGATE, verb, homonym, FRC_CATALOGUE);
        q.voice = static_cast<frc_voice>(voice);
        q.mood = static_cast<frc_mood>(mode);
        q.tense = static_cast<frc_tense>(tense);
        q.person = static_cast<frc_person>(person);
        auto r = query(q);
        return text(r);
    }
    /** Run conjugate on a worker; retains the engine even after this reader is destroyed. */
    std::future<std::optional<std::string>> conjugate_async(const std::string &verb, Voice voice,
                                                            Mode mode, Tense tense, Person person,
                                                            int homonym = 0) const {
        return background([=](const Conjugator &c) {
            return c.conjugate(verb, voice, mode, tense, person, homonym);
        });
    }
    /** Typed finite forms. Scoped bulk results omit missing forms; all-voice and single missing
     * output is nullopt. */
    std::optional<VoiceForms> raw_inferred_conjugation(const std::string &verb,
                                                       int homonym = 0) const {
        auto q = request(FRC_QUERY_CONJUGATE, verb, homonym, FRC_INFERRED);
        auto r = query(q);
        if (!r)
            return {};
        VoiceForms result;
        for (size_t i = 0; i < frc_response_row_count(r.get()); ++i) {
            auto row = frc_response_row(r.get(), i);
            result[static_cast<Voice>(row->voice)][static_cast<Mode>(row->mood)]
                  [static_cast<Tense>(row->tense)][static_cast<Person>(row->person)] = row->text;
        }
        return result;
    }
    /** Run raw_inferred_conjugation on a worker; retains the engine even after this reader is
     * destroyed. */
    std::future<std::optional<VoiceForms>> raw_inferred_conjugation_async(const std::string &verb,
                                                                          int homonym = 0) const {
        return background(
            [=](const Conjugator &c) { return c.raw_inferred_conjugation(verb, homonym); });
    }
    /** Typed finite forms. Scoped bulk results omit missing forms; all-voice and single missing
     * output is nullopt. */
    ModeForms raw_inferred_conjugation(const std::string &verb, Voice voice,
                                       int homonym = 0) const {
        auto q = request(FRC_QUERY_CONJUGATE, verb, homonym, FRC_INFERRED);
        q.voice = static_cast<frc_voice>(voice);
        auto r = query(q);
        ModeForms result;
        for (size_t i = 0; i < frc_response_row_count(r.get()); ++i) {
            auto row = frc_response_row(r.get(), i);
            result[static_cast<Mode>(row->mood)][static_cast<Tense>(row->tense)]
                  [static_cast<Person>(row->person)] = row->text;
        }
        return result;
    }
    /** Run raw_inferred_conjugation on a worker; retains the engine even after this reader is
     * destroyed. */
    std::future<ModeForms> raw_inferred_conjugation_async(const std::string &verb, Voice voice,
                                                          int homonym = 0) const {
        return background(
            [=](const Conjugator &c) { return c.raw_inferred_conjugation(verb, voice, homonym); });
    }
    /** Typed finite forms. Scoped bulk results omit missing forms; all-voice and single missing
     * output is nullopt. */
    TenseForms raw_inferred_conjugation(const std::string &verb, Voice voice, Mode mode,
                                        int homonym = 0) const {
        auto q = request(FRC_QUERY_CONJUGATE, verb, homonym, FRC_INFERRED);
        q.voice = static_cast<frc_voice>(voice);
        q.mood = static_cast<frc_mood>(mode);
        auto r = query(q);
        TenseForms result;
        for (size_t i = 0; i < frc_response_row_count(r.get()); ++i) {
            auto row = frc_response_row(r.get(), i);
            result[static_cast<Tense>(row->tense)][static_cast<Person>(row->person)] = row->text;
        }
        return result;
    }
    /** Run raw_inferred_conjugation on a worker; retains the engine even after this reader is
     * destroyed. */
    std::future<TenseForms> raw_inferred_conjugation_async(const std::string &verb, Voice voice,
                                                           Mode mode, int homonym = 0) const {
        return background([=](const Conjugator &c) {
            return c.raw_inferred_conjugation(verb, voice, mode, homonym);
        });
    }
    /** Typed finite forms. Scoped bulk results omit missing forms; all-voice and single missing
     * output is nullopt. */
    PersonForms raw_inferred_conjugation(const std::string &verb, Voice voice, Mode mode,
                                         Tense tense, int homonym = 0) const {
        auto q = request(FRC_QUERY_CONJUGATE, verb, homonym, FRC_INFERRED);
        q.voice = static_cast<frc_voice>(voice);
        q.mood = static_cast<frc_mood>(mode);
        q.tense = static_cast<frc_tense>(tense);
        auto r = query(q);
        PersonForms result;
        for (size_t i = 0; i < frc_response_row_count(r.get()); ++i) {
            auto row = frc_response_row(r.get(), i);
            result[static_cast<Person>(row->person)] = row->text;
        }
        return result;
    }
    /** Run raw_inferred_conjugation on a worker; retains the engine even after this reader is
     * destroyed. */
    std::future<PersonForms> raw_inferred_conjugation_async(const std::string &verb, Voice voice,
                                                            Mode mode, Tense tense,
                                                            int homonym = 0) const {
        return background([=](const Conjugator &c) {
            return c.raw_inferred_conjugation(verb, voice, mode, tense, homonym);
        });
    }
    /** Typed finite forms. Scoped bulk results omit missing forms; all-voice and single missing
     * output is nullopt. */
    std::optional<std::string> raw_inferred_conjugation(const std::string &verb, Voice voice,
                                                        Mode mode, Tense tense, Person person,
                                                        int homonym = 0) const {
        auto q = request(FRC_QUERY_CONJUGATE, verb, homonym, FRC_INFERRED);
        q.voice = static_cast<frc_voice>(voice);
        q.mood = static_cast<frc_mood>(mode);
        q.tense = static_cast<frc_tense>(tense);
        q.person = static_cast<frc_person>(person);
        auto r = query(q);
        return text(r);
    }
    /** Run raw_inferred_conjugation on a worker; retains the engine even after this reader is
     * destroyed. */
    std::future<std::optional<std::string>>
    raw_inferred_conjugation_async(const std::string &verb, Voice voice, Mode mode, Tense tense,
                                   Person person, int homonym = 0) const {
        return background([=](const Conjugator &c) {
            return c.raw_inferred_conjugation(verb, voice, mode, tense, person, homonym);
        });
    }
    /** Typed finite forms. Scoped bulk results omit missing forms; all-voice and single missing
     * output is nullopt. */
    std::optional<VoiceForms> guess_conjugation(const std::string &verb, int homonym = 0) const {
        auto q = request(FRC_QUERY_CONJUGATE, verb, homonym, FRC_GUESS);
        auto r = query(q);
        if (!r)
            return {};
        VoiceForms result;
        for (size_t i = 0; i < frc_response_row_count(r.get()); ++i) {
            auto row = frc_response_row(r.get(), i);
            result[static_cast<Voice>(row->voice)][static_cast<Mode>(row->mood)]
                  [static_cast<Tense>(row->tense)][static_cast<Person>(row->person)] = row->text;
        }
        return result;
    }
    /** Run guess_conjugation on a worker; retains the engine even after this reader is destroyed.
     */
    std::future<std::optional<VoiceForms>> guess_conjugation_async(const std::string &verb,
                                                                   int homonym = 0) const {
        return background([=](const Conjugator &c) { return c.guess_conjugation(verb, homonym); });
    }
    /** Typed finite forms. Scoped bulk results omit missing forms; all-voice and single missing
     * output is nullopt. */
    ModeForms guess_conjugation(const std::string &verb, Voice voice, int homonym = 0) const {
        auto q = request(FRC_QUERY_CONJUGATE, verb, homonym, FRC_GUESS);
        q.voice = static_cast<frc_voice>(voice);
        auto r = query(q);
        ModeForms result;
        for (size_t i = 0; i < frc_response_row_count(r.get()); ++i) {
            auto row = frc_response_row(r.get(), i);
            result[static_cast<Mode>(row->mood)][static_cast<Tense>(row->tense)]
                  [static_cast<Person>(row->person)] = row->text;
        }
        return result;
    }
    /** Run guess_conjugation on a worker; retains the engine even after this reader is destroyed.
     */
    std::future<ModeForms> guess_conjugation_async(const std::string &verb, Voice voice,
                                                   int homonym = 0) const {
        return background(
            [=](const Conjugator &c) { return c.guess_conjugation(verb, voice, homonym); });
    }
    /** Typed finite forms. Scoped bulk results omit missing forms; all-voice and single missing
     * output is nullopt. */
    TenseForms guess_conjugation(const std::string &verb, Voice voice, Mode mode,
                                 int homonym = 0) const {
        auto q = request(FRC_QUERY_CONJUGATE, verb, homonym, FRC_GUESS);
        q.voice = static_cast<frc_voice>(voice);
        q.mood = static_cast<frc_mood>(mode);
        auto r = query(q);
        TenseForms result;
        for (size_t i = 0; i < frc_response_row_count(r.get()); ++i) {
            auto row = frc_response_row(r.get(), i);
            result[static_cast<Tense>(row->tense)][static_cast<Person>(row->person)] = row->text;
        }
        return result;
    }
    /** Run guess_conjugation on a worker; retains the engine even after this reader is destroyed.
     */
    std::future<TenseForms> guess_conjugation_async(const std::string &verb, Voice voice, Mode mode,
                                                    int homonym = 0) const {
        return background(
            [=](const Conjugator &c) { return c.guess_conjugation(verb, voice, mode, homonym); });
    }
    /** Typed finite forms. Scoped bulk results omit missing forms; all-voice and single missing
     * output is nullopt. */
    PersonForms guess_conjugation(const std::string &verb, Voice voice, Mode mode, Tense tense,
                                  int homonym = 0) const {
        auto q = request(FRC_QUERY_CONJUGATE, verb, homonym, FRC_GUESS);
        q.voice = static_cast<frc_voice>(voice);
        q.mood = static_cast<frc_mood>(mode);
        q.tense = static_cast<frc_tense>(tense);
        auto r = query(q);
        PersonForms result;
        for (size_t i = 0; i < frc_response_row_count(r.get()); ++i) {
            auto row = frc_response_row(r.get(), i);
            result[static_cast<Person>(row->person)] = row->text;
        }
        return result;
    }
    /** Run guess_conjugation on a worker; retains the engine even after this reader is destroyed.
     */
    std::future<PersonForms> guess_conjugation_async(const std::string &verb, Voice voice,
                                                     Mode mode, Tense tense,
                                                     int homonym = 0) const {
        return background([=](const Conjugator &c) {
            return c.guess_conjugation(verb, voice, mode, tense, homonym);
        });
    }
    /** Typed finite forms. Scoped bulk results omit missing forms; all-voice and single missing
     * output is nullopt. */
    std::optional<std::string> guess_conjugation(const std::string &verb, Voice voice, Mode mode,
                                                 Tense tense, Person person,
                                                 int homonym = 0) const {
        auto q = request(FRC_QUERY_CONJUGATE, verb, homonym, FRC_GUESS);
        q.voice = static_cast<frc_voice>(voice);
        q.mood = static_cast<frc_mood>(mode);
        q.tense = static_cast<frc_tense>(tense);
        q.person = static_cast<frc_person>(person);
        auto r = query(q);
        return text(r);
    }
    /** Run guess_conjugation on a worker; retains the engine even after this reader is destroyed.
     */
    std::future<std::optional<std::string>> guess_conjugation_async(const std::string &verb,
                                                                    Voice voice, Mode mode,
                                                                    Tense tense, Person person,
                                                                    int homonym = 0) const {
        return background([=](const Conjugator &c) {
            return c.guess_conjugation(verb, voice, mode, tense, person, homonym);
        });
    }
    /** Typed nonpersonal forms; gender/number is selected by tense. Predictions may be unattested.
     */
    std::optional<std::string> participle(const std::string &verb, Voice voice, Tense tense,
                                          int homonym = 0) const {
        auto q = request(FRC_QUERY_PARTICIPLE, verb, homonym, FRC_CATALOGUE);
        q.voice = static_cast<frc_voice>(voice);
        q.tense = static_cast<frc_tense>(tense);
        return text(query(q));
    }
    /** Run participle on a worker; retains the engine even after this reader is destroyed. */
    std::future<std::optional<std::string>> participle_async(const std::string &verb, Voice voice,
                                                             Tense tense, int homonym = 0) const {
        return background(
            [=](const Conjugator &c) { return c.participle(verb, voice, tense, homonym); });
    }
    /** Typed nonpersonal forms; gender/number is selected by tense. Predictions may be unattested.
     */
    std::optional<std::string> gerondif(const std::string &verb, Voice voice, Tense tense,
                                        int homonym = 0) const {
        auto q = request(FRC_QUERY_GERONDIF, verb, homonym, FRC_CATALOGUE);
        q.voice = static_cast<frc_voice>(voice);
        q.tense = static_cast<frc_tense>(tense);
        return text(query(q));
    }
    /** Run gerondif on a worker; retains the engine even after this reader is destroyed. */
    std::future<std::optional<std::string>> gerondif_async(const std::string &verb, Voice voice,
                                                           Tense tense, int homonym = 0) const {
        return background(
            [=](const Conjugator &c) { return c.gerondif(verb, voice, tense, homonym); });
    }
    /** Typed nonpersonal forms; gender/number is selected by tense. Predictions may be unattested.
     */
    std::map<Tense, std::string> participles(const std::string &verb, Voice voice,
                                             int homonym = 0) const {
        auto q = request(FRC_QUERY_PARTICIPLES, verb, homonym, FRC_CATALOGUE);
        q.voice = static_cast<frc_voice>(voice);
        auto r = query(q);
        std::map<Tense, std::string> result;
        for (size_t i = 0; i < frc_response_row_count(r.get()); ++i) {
            auto row = frc_response_row(r.get(), i);
            result[static_cast<Tense>(row->tense)] = row->text;
        }
        return result;
    }
    /** Typed nonpersonal forms; gender/number is selected by tense. Predictions may be unattested.
     */
    std::optional<std::string> raw_inferred_participle(const std::string &verb, Voice voice,
                                                       Tense tense, int homonym = 0) const {
        auto q = request(FRC_QUERY_PARTICIPLE, verb, homonym, FRC_INFERRED);
        q.voice = static_cast<frc_voice>(voice);
        q.tense = static_cast<frc_tense>(tense);
        return text(query(q));
    }
    /** Run raw_inferred_participle on a worker; retains the engine even after this reader is
     * destroyed. */
    std::future<std::optional<std::string>> raw_inferred_participle_async(const std::string &verb,
                                                                          Voice voice, Tense tense,
                                                                          int homonym = 0) const {
        return background([=](const Conjugator &c) {
            return c.raw_inferred_participle(verb, voice, tense, homonym);
        });
    }
    /** Typed nonpersonal forms; gender/number is selected by tense. Predictions may be unattested.
     */
    std::optional<std::string> raw_inferred_gerondif(const std::string &verb, Voice voice,
                                                     Tense tense, int homonym = 0) const {
        auto q = request(FRC_QUERY_GERONDIF, verb, homonym, FRC_INFERRED);
        q.voice = static_cast<frc_voice>(voice);
        q.tense = static_cast<frc_tense>(tense);
        return text(query(q));
    }
    /** Run raw_inferred_gerondif on a worker; retains the engine even after this reader is
     * destroyed. */
    std::future<std::optional<std::string>> raw_inferred_gerondif_async(const std::string &verb,
                                                                        Voice voice, Tense tense,
                                                                        int homonym = 0) const {
        return background([=](const Conjugator &c) {
            return c.raw_inferred_gerondif(verb, voice, tense, homonym);
        });
    }
    /** Typed nonpersonal forms; gender/number is selected by tense. Predictions may be unattested.
     */
    std::map<Tense, std::string> raw_inferred_participles(const std::string &verb, Voice voice,
                                                          int homonym = 0) const {
        auto q = request(FRC_QUERY_PARTICIPLES, verb, homonym, FRC_INFERRED);
        q.voice = static_cast<frc_voice>(voice);
        auto r = query(q);
        std::map<Tense, std::string> result;
        for (size_t i = 0; i < frc_response_row_count(r.get()); ++i) {
            auto row = frc_response_row(r.get(), i);
            result[static_cast<Tense>(row->tense)] = row->text;
        }
        return result;
    }
    /** Typed nonpersonal forms; gender/number is selected by tense. Predictions may be unattested.
     */
    std::optional<std::string> guess_participle(const std::string &verb, Voice voice, Tense tense,
                                                int homonym = 0) const {
        auto q = request(FRC_QUERY_PARTICIPLE, verb, homonym, FRC_GUESS);
        q.voice = static_cast<frc_voice>(voice);
        q.tense = static_cast<frc_tense>(tense);
        return text(query(q));
    }
    /** Run guess_participle on a worker; retains the engine even after this reader is destroyed. */
    std::future<std::optional<std::string>> guess_participle_async(const std::string &verb,
                                                                   Voice voice, Tense tense,
                                                                   int homonym = 0) const {
        return background(
            [=](const Conjugator &c) { return c.guess_participle(verb, voice, tense, homonym); });
    }
    /** Typed nonpersonal forms; gender/number is selected by tense. Predictions may be unattested.
     */
    std::optional<std::string> guess_gerondif(const std::string &verb, Voice voice, Tense tense,
                                              int homonym = 0) const {
        auto q = request(FRC_QUERY_GERONDIF, verb, homonym, FRC_GUESS);
        q.voice = static_cast<frc_voice>(voice);
        q.tense = static_cast<frc_tense>(tense);
        return text(query(q));
    }
    /** Run guess_gerondif on a worker; retains the engine even after this reader is destroyed. */
    std::future<std::optional<std::string>>
    guess_gerondif_async(const std::string &verb, Voice voice, Tense tense, int homonym = 0) const {
        return background(
            [=](const Conjugator &c) { return c.guess_gerondif(verb, voice, tense, homonym); });
    }
    /** Typed nonpersonal forms; gender/number is selected by tense. Predictions may be unattested.
     */
    std::map<Tense, std::string> guess_participles(const std::string &verb, Voice voice,
                                                   int homonym = 0) const {
        auto q = request(FRC_QUERY_PARTICIPLES, verb, homonym, FRC_GUESS);
        q.voice = static_cast<frc_voice>(voice);
        auto r = query(q);
        std::map<Tense, std::string> result;
        for (size_t i = 0; i < frc_response_row_count(r.get()); ++i) {
            auto row = frc_response_row(r.get(), i);
            result[static_cast<Tense>(row->tense)] = row->text;
        }
        return result;
    }
    /** Typed catalogue query; alternative spelling falls back to primary, and missing output is
     * nullopt/false. */
    std::optional<std::string> conjugate_alternative(const std::string &verb, Voice voice,
                                                     Mode mode, Tense tense, Person person,
                                                     int homonym = 0) const {
        auto q = request(FRC_QUERY_CONJUGATE, verb, homonym);
        q.spelling = FRC_ALTERNATIVE;
        q.voice = static_cast<frc_voice>(voice);
        q.tense = static_cast<frc_tense>(tense);
        q.mood = static_cast<frc_mood>(mode);
        q.person = static_cast<frc_person>(person);
        auto r = query(q);
        return text(r);
    }
    /** Run conjugate_alternative on a worker; retains the engine even after this reader is
     * destroyed. */
    std::future<std::optional<std::string>> conjugate_alternative_async(const std::string &verb,
                                                                        Voice voice, Mode mode,
                                                                        Tense tense, Person person,
                                                                        int homonym = 0) const {
        return background([=](const Conjugator &c) {
            return c.conjugate_alternative(verb, voice, mode, tense, person, homonym);
        });
    }
    /** Typed catalogue query; alternative spelling falls back to primary, and missing output is
     * nullopt/false. */
    bool has_alternative_form(const std::string &verb, Voice voice, Mode mode, Tense tense,
                              Person person, int homonym = 0) const {
        auto q = request(FRC_QUERY_HAS_ALTERNATIVE_FORM, verb, homonym);
        q.spelling = FRC_ALL;
        q.voice = static_cast<frc_voice>(voice);
        q.tense = static_cast<frc_tense>(tense);
        q.mood = static_cast<frc_mood>(mode);
        q.person = static_cast<frc_person>(person);
        auto r = query(q);
        return frc_response_number(r.get());
    }
    /** Typed catalogue query; alternative spelling falls back to primary, and missing output is
     * nullopt/false. */
    std::optional<std::string> participle_alternative(const std::string &verb, Voice voice,
                                                      Tense tense, int homonym = 0) const {
        auto q = request(FRC_QUERY_PARTICIPLE, verb, homonym);
        q.spelling = FRC_ALTERNATIVE;
        q.voice = static_cast<frc_voice>(voice);
        q.tense = static_cast<frc_tense>(tense);
        auto r = query(q);
        return text(r);
    }
    /** Run participle_alternative on a worker; retains the engine even after this reader is
     * destroyed. */
    std::future<std::optional<std::string>> participle_alternative_async(const std::string &verb,
                                                                         Voice voice, Tense tense,
                                                                         int homonym = 0) const {
        return background([=](const Conjugator &c) {
            return c.participle_alternative(verb, voice, tense, homonym);
        });
    }
    /** Typed catalogue query; alternative spelling falls back to primary, and missing output is
     * nullopt/false. */
    bool has_alternative_participle(const std::string &verb, Voice voice, Tense tense,
                                    int homonym = 0) const {
        auto q = request(FRC_QUERY_HAS_ALTERNATIVE_PARTICIPLE, verb, homonym);
        q.spelling = FRC_ALL;
        q.voice = static_cast<frc_voice>(voice);
        q.tense = static_cast<frc_tense>(tense);
        auto r = query(q);
        return frc_response_number(r.get());
    }
    /** Typed catalogue query; alternative spelling falls back to primary, and missing output is
     * nullopt/false. */
    std::optional<std::string> get_pronoun(const std::string &verb, Voice voice, Mode mode,
                                           Tense tense, Person person, int homonym = 0) const {
        auto q = request(FRC_QUERY_PRONOUN, verb, homonym);
        q.spelling = FRC_PRIMARY;
        q.voice = static_cast<frc_voice>(voice);
        q.tense = static_cast<frc_tense>(tense);
        q.mood = static_cast<frc_mood>(mode);
        q.person = static_cast<frc_person>(person);
        auto r = query(q);
        return text(r);
    }
    /** Run get_pronoun on a worker; retains the engine even after this reader is destroyed. */
    std::future<std::optional<std::string>> get_pronoun_async(const std::string &verb, Voice voice,
                                                              Mode mode, Tense tense, Person person,
                                                              int homonym = 0) const {
        return background([=](const Conjugator &c) {
            return c.get_pronoun(verb, voice, mode, tense, person, homonym);
        });
    }
    /** Typed catalogue query; alternative spelling falls back to primary, and missing output is
     * nullopt/false. */
    std::optional<std::string> conjugate_with_pronoun(const std::string &verb, Voice voice,
                                                      Mode mode, Tense tense, Person person,
                                                      int homonym = 0) const {
        auto q = request(FRC_QUERY_WITH_PRONOUN, verb, homonym);
        q.spelling = FRC_PRIMARY;
        q.voice = static_cast<frc_voice>(voice);
        q.tense = static_cast<frc_tense>(tense);
        q.mood = static_cast<frc_mood>(mode);
        q.person = static_cast<frc_person>(person);
        auto r = query(q);
        return text(r);
    }
    /** Run conjugate_with_pronoun on a worker; retains the engine even after this reader is
     * destroyed. */
    std::future<std::optional<std::string>> conjugate_with_pronoun_async(const std::string &verb,
                                                                         Voice voice, Mode mode,
                                                                         Tense tense, Person person,
                                                                         int homonym = 0) const {
        return background([=](const Conjugator &c) {
            return c.conjugate_with_pronoun(verb, voice, mode, tense, person, homonym);
        });
    }
    /** Typed catalogue query; alternative spelling falls back to primary, and missing output is
     * nullopt/false. */
    std::optional<std::string> conjugate_alternative_with_pronoun(const std::string &verb,
                                                                  Voice voice, Mode mode,
                                                                  Tense tense, Person person,
                                                                  int homonym = 0) const {
        auto q = request(FRC_QUERY_WITH_PRONOUN, verb, homonym);
        q.spelling = FRC_ALTERNATIVE;
        q.voice = static_cast<frc_voice>(voice);
        q.tense = static_cast<frc_tense>(tense);
        q.mood = static_cast<frc_mood>(mode);
        q.person = static_cast<frc_person>(person);
        auto r = query(q);
        return text(r);
    }
    /** Run conjugate_alternative_with_pronoun on a worker; retains the engine even after this
     * reader is destroyed. */
    std::future<std::optional<std::string>>
    conjugate_alternative_with_pronoun_async(const std::string &verb, Voice voice, Mode mode,
                                             Tense tense, Person person, int homonym = 0) const {
        return background([=](const Conjugator &c) {
            return c.conjugate_alternative_with_pronoun(verb, voice, mode, tense, person, homonym);
        });
    }
    /** Catalogue structure in raw-label order; persons instead group identical spellings in
     * declaration order. */
    std::vector<Voice> voices(const std::string &verb, int homonym = 0) const {
        auto q = request(FRC_QUERY_VOICES, verb, homonym);
        auto r = query(q);
        std::vector<Voice> result;
        for (size_t i = 0; i < frc_response_value_count(r.get()); ++i)
            result.push_back(static_cast<Voice>(frc_response_value(r.get(), i)));
        return result;
    }
    /** Catalogue structure in raw-label order; persons instead group identical spellings in
     * declaration order. */
    std::vector<Mode> modes(const std::string &verb, Voice voice, int homonym = 0) const {
        auto q = request(FRC_QUERY_MODES, verb, homonym);
        q.voice = static_cast<frc_voice>(voice);
        auto r = query(q);
        std::vector<Mode> result;
        for (size_t i = 0; i < frc_response_value_count(r.get()); ++i)
            result.push_back(static_cast<Mode>(frc_response_value(r.get(), i)));
        return result;
    }
    /** Catalogue structure in raw-label order; persons instead group identical spellings in
     * declaration order. */
    std::vector<Tense> tenses(const std::string &verb, Voice voice, Mode mode,
                              int homonym = 0) const {
        auto q = request(FRC_QUERY_TENSES, verb, homonym);
        q.voice = static_cast<frc_voice>(voice);
        q.mood = static_cast<frc_mood>(mode);
        auto r = query(q);
        std::vector<Tense> result;
        for (size_t i = 0; i < frc_response_value_count(r.get()); ++i)
            result.push_back(static_cast<Tense>(frc_response_value(r.get(), i)));
        return result;
    }
    /** Catalogue structure in raw-label order; persons instead group identical spellings in
     * declaration order. */
    std::vector<Person> persons(const std::string &verb, Voice voice, Mode mode, Tense tense,
                                int homonym = 0) const {
        auto q = request(FRC_QUERY_PERSONS, verb, homonym);
        q.voice = static_cast<frc_voice>(voice);
        q.mood = static_cast<frc_mood>(mode);
        q.tense = static_cast<frc_tense>(tense);
        auto r = query(q);
        std::vector<Person> result;
        for (size_t i = 0; i < frc_response_value_count(r.get()); ++i)
            result.push_back(static_cast<Person>(frc_response_value(r.get(), i)));
        return result;
    }
    /** Common spelling using the selected strategy; empty is valid, nullopt means no usable forms.
     */
    std::optional<std::string> raw_inferred_common_prefix(const std::string &verb,
                                                          int homonym = 0) const {
        return common_prefix(verb, FRC_INFERRED, homonym);
    }
    /** Run raw_inferred_common_prefix on a worker; retains the engine even after this reader is
     * destroyed. */
    std::future<std::optional<std::string>>
    raw_inferred_common_prefix_async(const std::string &verb, int homonym = 0) const {
        return background(
            [=](const Conjugator &c) { return c.raw_inferred_common_prefix(verb, homonym); });
    }
    /** Common spelling using the selected strategy; empty is valid, nullopt means no usable forms.
     */
    std::optional<std::string> guess_common_prefix(const std::string &verb, int homonym = 0) const {
        return common_prefix(verb, FRC_GUESS, homonym);
    }
    /** Run guess_common_prefix on a worker; retains the engine even after this reader is destroyed.
     */
    std::future<std::optional<std::string>> guess_common_prefix_async(const std::string &verb,
                                                                      int homonym = 0) const {
        return background(
            [=](const Conjugator &c) { return c.guess_common_prefix(verb, homonym); });
    }
    /** Catalogue common-prefix query on a worker; retains the reader engine. */
    std::future<std::optional<std::string>> common_prefix_async(const std::string &verb,
                                                                int homonym = 0) const {
        return background(
            [=](const Conjugator &c) { return c.common_prefix(verb, FRC_CATALOGUE, homonym); });
    }
};
} // namespace frconjugation
#endif
