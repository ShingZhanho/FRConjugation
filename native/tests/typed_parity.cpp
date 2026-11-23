#include "frconjugation.hpp"
#include "fixtures.hpp"
#include <algorithm>
#include <fstream>
#include <iostream>
#include <sstream>
#include <future>
#include <chrono>
using namespace frconjugation;
using Text = std::optional<std::string>;
std::string join(const std::vector<std::string> &items, const std::string &separator) {
    std::string result;
    for (size_t i = 0; i < items.size(); ++i) {
        if (i)
            result += separator;
        result += items[i];
    }
    return result;
}
template <class T> std::string labels(const std::vector<T> &items) {
    std::vector<std::string> values;
    for (auto value : items)
        values.emplace_back(label(value));
    return join(values, ",");
}
template <class K, class V>
void walk(const std::map<K, V> &value, std::vector<std::string> path,
          std::vector<std::string> &out) {
    for (auto &item : value) {
        auto next = path;
        next.push_back(label(item.first));
        if constexpr (std::is_same_v<V, std::string>)
            out.push_back(join(next, "|") + "=" + item.second);
        else
            walk(item.second, next, out);
    }
}
template <class K, class V>
Text flatten(const std::map<K, V> &value, const std::vector<std::string> &prefix = {}) {
    std::vector<std::string> lines;
    walk(value, prefix, lines);
    std::sort(lines.begin(), lines.end());
    return join(lines, "\n");
}
Text flatten(const std::optional<VoiceForms> &value, const std::vector<std::string> &prefix = {}) {
    return value ? flatten(*value, prefix) : Text();
}
Text flatten(const Text &value, const std::vector<std::string> &prefix = {}) {
    (void)prefix;
    return value;
}
int parse(const std::string &value, const char *(*labeler)(int)) {
    if (value == "-")
        return -1;
    for (int i = 0; labeler(i); ++i)
        if (value == labeler(i))
            return i;
    throw std::runtime_error("Unknown label");
}
const char *voice_label(int i) {
    return frc_voice_label(static_cast<frc_voice>(i));
}
const char *mode_label(int i) {
    return frc_mood_label(static_cast<frc_mood>(i));
}
const char *tense_label(int i) {
    return frc_tense_label(static_cast<frc_tense>(i));
}
const char *person_label(int i) {
    return frc_person_label(static_cast<frc_person>(i));
}
frc_request make_request(const std::vector<std::string> &r) {
    static const std::map<std::string, frc_operation> ops = {
        {"finite", FRC_QUERY_CONJUGATE},
        {"participle", FRC_QUERY_PARTICIPLE},
        {"participles", FRC_QUERY_PARTICIPLES},
        {"gerondif", FRC_QUERY_GERONDIF},
        {"alternative", FRC_QUERY_CONJUGATE},
        {"has_alternative", FRC_QUERY_HAS_ALTERNATIVE_FORM},
        {"participle_alternative", FRC_QUERY_PARTICIPLE},
        {"has_alternative_participle", FRC_QUERY_HAS_ALTERNATIVE_PARTICIPLE},
        {"pronoun", FRC_QUERY_PRONOUN},
        {"with_pronoun", FRC_QUERY_WITH_PRONOUN},
        {"alternative_with_pronoun", FRC_QUERY_WITH_PRONOUN},
        {"voices", FRC_QUERY_VOICES},
        {"modes", FRC_QUERY_MODES},
        {"tenses", FRC_QUERY_TENSES},
        {"persons", FRC_QUERY_PERSONS},
        {"all_verbs", FRC_QUERY_ALL_VERBS},
        {"verb_count", FRC_QUERY_VERB_COUNT},
        {"has_verb", FRC_QUERY_HAS_VERB},
        {"has_homonyms", FRC_QUERY_HAS_HOMONYMS},
        {"homonym_count", FRC_QUERY_HOMONYM_COUNT},
        {"homonym_indices", FRC_QUERY_HOMONYM_INDICES},
        {"h_aspire", FRC_QUERY_IS_H_ASPIRE},
        {"blocking", FRC_QUERY_BLOCKS_ELISION},
        {"reform", FRC_QUERY_IS_1990_REFORM},
        {"variant", FRC_QUERY_REFORM_VARIANT}};
    auto q = frc_request_init(ops.at(r[1]), r[2].c_str());
    q.voice = static_cast<frc_voice>(parse(r[3], voice_label));
    q.mood = static_cast<frc_mood>(parse(r[4], mode_label));
    q.tense = static_cast<frc_tense>(parse(r[5], tense_label));
    q.person = static_cast<frc_person>(parse(r[6], person_label));
    q.homonym = std::stoi(r[7]);
    q.prediction = r[8] == "inferred" ? FRC_INFERRED : r[8] == "guess" ? FRC_GUESS : FRC_CATALOGUE;
    if (r[1] == "alternative" || r[1] == "participle_alternative" ||
        r[1] == "alternative_with_pronoun")
        q.spelling = FRC_ALTERNATIVE;
    return q;
}
Text c_result(const frc_request &q, frc_status status, frc_response *raw) {
    std::unique_ptr<frc_response, decltype(&frc_response_free)> owner(raw, frc_response_free);
    if (status == FRC_MISSING) {
        if (raw)
            throw std::runtime_error("Missing result owns unexpected response");
        return {};
    }
    if (status != FRC_OK)
        throw std::runtime_error("C API error " + std::to_string(status));
    if (auto text = frc_response_text(raw))
        return text;
    std::vector<std::string> values;
    if (q.operation == FRC_QUERY_CONJUGATE || q.operation == FRC_QUERY_PARTICIPLES) {
        for (size_t i = 0; i < frc_response_row_count(raw); ++i) {
            auto row = frc_response_row(raw, i);
            std::string key;
            if (q.operation == FRC_QUERY_PARTICIPLES)
                key = frc_tense_label(row->tense);
            else
                key = std::string(frc_voice_label(row->voice)) + "|" + frc_mood_label(row->mood) +
                      "|" + frc_tense_label(row->tense) + "|" + frc_person_label(row->person);
            values.push_back(key + "=" + row->text);
        }
        std::sort(values.begin(), values.end());
        return join(values, "\n");
    }
    if (q.operation == FRC_QUERY_ALL_VERBS) {
        for (size_t i = 0; i < frc_response_string_count(raw); ++i)
            values.emplace_back(frc_response_string(raw, i));
        return join(values, ",");
    }
    if (q.operation == FRC_QUERY_HOMONYM_INDICES ||
        (q.operation >= FRC_QUERY_VOICES && q.operation <= FRC_QUERY_PERSONS)) {
        for (size_t i = 0; i < frc_response_value_count(raw); ++i) {
            int v = frc_response_value(raw, i);
            values.push_back(q.operation == FRC_QUERY_HOMONYM_INDICES ? std::to_string(v)
                             : q.operation == FRC_QUERY_VOICES        ? voice_label(v)
                             : q.operation == FRC_QUERY_MODES         ? mode_label(v)
                             : q.operation == FRC_QUERY_TENSES        ? tense_label(v)
                                                                      : person_label(v));
        }
        return join(values, ",");
    }
    return std::to_string(frc_response_number(raw));
}
Text cpp_result(const Conjugator &c, const std::vector<std::string> &r, const frc_request &q) {
    const auto &op = r[1];
    const auto &verb = r[2];
    int h = q.homonym;
    auto v = static_cast<Voice>(q.voice);
    auto m = static_cast<Mode>(q.mood);
    auto t = static_cast<Tense>(q.tense);
    auto p = static_cast<Person>(q.person);
    if (op == "all_verbs")
        return join(c.all_verbs(), ",");
    if (op == "verb_count")
        return std::to_string(c.verb_count());
    if (op == "has_verb")
        return std::to_string(c.has_verb(verb));
    if (op == "has_homonyms")
        return std::to_string(c.has_homonyms(verb));
    if (op == "homonym_count")
        return std::to_string(c.homonym_count(verb));
    if (op == "h_aspire")
        return std::to_string(c.is_h_aspire(verb));
    if (op == "blocking")
        return std::to_string(c.blocks_elision_and_liaison(verb, h));
    if (op == "reform")
        return std::to_string(c.is_1990_reform(verb));
    if (op == "variant")
        return c.reform_variant(verb);
    if (op == "voices")
        return labels(c.voices(verb, h));
    if (op == "modes")
        return labels(c.modes(verb, v, h));
    if (op == "tenses")
        return labels(c.tenses(verb, v, m, h));
    if (op == "persons")
        return labels(c.persons(verb, v, m, t, h));
    if (op == "alternative")
        return c.conjugate_alternative(verb, v, m, t, p, h);
    if (op == "has_alternative")
        return std::to_string(c.has_alternative_form(verb, v, m, t, p, h));
    if (op == "participle_alternative")
        return c.participle_alternative(verb, v, t, h);
    if (op == "has_alternative_participle")
        return std::to_string(c.has_alternative_participle(verb, v, t, h));
    if (op == "pronoun")
        return c.get_pronoun(verb, v, m, t, p, h);
    if (op == "with_pronoun")
        return c.conjugate_with_pronoun(verb, v, m, t, p, h);
    if (op == "alternative_with_pronoun")
        return c.conjugate_alternative_with_pronoun(verb, v, m, t, p, h);
    if (op == "homonym_indices") {
        std::vector<std::string> values;
        for (auto n : c.homonym_indices(verb))
            values.push_back(std::to_string(n));
        return join(values, ",");
    }
    if (r[8] == "catalogue") {
        if (op == "participle")
            return c.participle(verb, v, t, h);
        if (op == "gerondif")
            return c.gerondif(verb, v, t, h);
        if (op == "participles")
            return flatten(c.participles(verb, v, h));
        if (q.person != FRC_PERSON_ANY)
            return flatten(c.conjugate(verb, v, m, t, p, h), {r[3], r[4], r[5], r[6]});
        if (q.tense != FRC_TENSE_ANY)
            return flatten(c.conjugate(verb, v, m, t, h), {r[3], r[4], r[5]});
        if (q.mood != FRC_MOOD_ANY)
            return flatten(c.conjugate(verb, v, m, h), {r[3], r[4]});
        if (q.voice != FRC_VOICE_ANY)
            return flatten(c.conjugate(verb, v, h), {r[3]});
        if (true)
            return flatten(c.conjugate(verb, h), {});
    }
    if (r[8] == "inferred") {
        if (op == "participle")
            return c.raw_inferred_participle(verb, v, t, h);
        if (op == "gerondif")
            return c.raw_inferred_gerondif(verb, v, t, h);
        if (op == "participles")
            return flatten(c.raw_inferred_participles(verb, v, h));
        if (q.person != FRC_PERSON_ANY)
            return flatten(c.raw_inferred_conjugation(verb, v, m, t, p, h),
                           {r[3], r[4], r[5], r[6]});
        if (q.tense != FRC_TENSE_ANY)
            return flatten(c.raw_inferred_conjugation(verb, v, m, t, h), {r[3], r[4], r[5]});
        if (q.mood != FRC_MOOD_ANY)
            return flatten(c.raw_inferred_conjugation(verb, v, m, h), {r[3], r[4]});
        if (q.voice != FRC_VOICE_ANY)
            return flatten(c.raw_inferred_conjugation(verb, v, h), {r[3]});
        if (true)
            return flatten(c.raw_inferred_conjugation(verb, h), {});
    }
    if (r[8] == "guess") {
        if (op == "participle")
            return c.guess_participle(verb, v, t, h);
        if (op == "gerondif")
            return c.guess_gerondif(verb, v, t, h);
        if (op == "participles")
            return flatten(c.guess_participles(verb, v, h));
        if (q.person != FRC_PERSON_ANY)
            return flatten(c.guess_conjugation(verb, v, m, t, p, h), {r[3], r[4], r[5], r[6]});
        if (q.tense != FRC_TENSE_ANY)
            return flatten(c.guess_conjugation(verb, v, m, t, h), {r[3], r[4], r[5]});
        if (q.mood != FRC_MOOD_ANY)
            return flatten(c.guess_conjugation(verb, v, m, h), {r[3], r[4]});
        if (q.voice != FRC_VOICE_ANY)
            return flatten(c.guess_conjugation(verb, v, h), {r[3]});
        if (true)
            return flatten(c.guess_conjugation(verb, h), {});
    }
    throw std::runtime_error("Unknown C++ query");
}
int main(int argc, char **argv) {
    try {
        if (argc != 2)
            throw std::runtime_error("Expected fixture path");
        std::ifstream input(argv[1]);
        std::string line;
        std::getline(input, line);
        Conjugator c;
        size_t count = 0;
        while (std::getline(input, line)) {
            auto r = fields(line);
            if (r.size() != 10)
                throw std::runtime_error("Bad row");
            auto expected = decode(r[9]);
            if (r[1].find("enum_") == 0 || r[1] == "person_pronouns") {
                auto labeler = r[1] == "enum_voice"   ? voice_label
                               : r[1] == "enum_mode"  ? mode_label
                               : r[1] == "enum_tense" ? tense_label
                                                      : person_label;
                std::vector<std::string> values;
                for (int i = 0; labeler(i); ++i)
                    values.emplace_back(r[1] == "person_pronouns"
                                            ? frc_person_pronoun(static_cast<frc_person>(i))
                                            : labeler(i));
                if (join(values, ",") != expected)
                    throw std::runtime_error("Enum mismatch " + r[0]);
            } else {
                auto q = make_request(r);
                frc_response *response = nullptr;
                auto status = frc_query(c.native_handle(), &q, &response);
                if (c_result(q, status, response) != expected)
                    throw std::runtime_error("C mismatch " + r[0] + " " + r[1]);
                if (cpp_result(c, r, q) != expected)
                    throw std::runtime_error("C++ mismatch " + r[0] + " " + r[1]);
                // Exercise every request asynchronously, including owned results after releasing
                // the input reader.
                std::promise<Text> completion;
                auto future = completion.get_future();
                struct Context {
                    std::promise<Text> *promise;
                    frc_request request;
                } context{&completion, q};
                frc_engine *engine = nullptr;
                if (frc_create(&engine) != FRC_OK)
                    throw std::runtime_error("Create failed");
                auto scheduled = frc_query_async(
                    engine, &q,
                    [](frc_status status, frc_response *value, void *pointer) {
                        auto &ctx = *static_cast<Context *>(pointer);
                        try {
                            ctx.promise->set_value(c_result(ctx.request, status, value));
                        } catch (...) {
                            ctx.promise->set_exception(std::current_exception());
                        }
                    },
                    &context);
                frc_destroy(engine);
                if (scheduled != FRC_OK)
                    throw std::runtime_error("Schedule failed");
                if (future.wait_for(std::chrono::seconds(30)) != std::future_status::ready)
                    std::terminate();
                if (future.get() != expected)
                    throw std::runtime_error("C async mismatch " + r[0]);
            }
            ++count;
        }
        if (!input.eof() || count == 0)
            throw std::runtime_error("Missing cases");
        if (&Conjugator::get_shared_async().get().get() != &Conjugator::get_shared())
            throw std::runtime_error("Shared identity");
        auto loaded = Conjugator::load_async().get();
        std::promise<frc_engine *> initialized;
        auto ready = initialized.get_future();
        if (frc_get_shared_async(
                [](frc_status status, frc_engine *engine, void *context) {
                    auto &promise = *static_cast<std::promise<frc_engine *> *>(context);
                    if (status == FRC_OK)
                        promise.set_value(engine);
                    else
                        promise.set_exception(
                            std::make_exception_ptr(std::runtime_error("Async load failed")));
                },
                &initialized) != FRC_OK)
            throw std::runtime_error("Async load scheduling failed");
        if (ready.wait_for(std::chrono::seconds(30)) != std::future_status::ready)
            std::terminate();
        frc_destroy(ready.get());

        auto future = [] {
            Conjugator local;
            return local.conjugate_async("manger", Voice::ActiveAvoir, Mode::Indicatif,
                                         Tense::Present, Person::FirstPluralMasculine);
        }();
        if (future.get() != Text("mangeons"))
            throw std::runtime_error("Future lifetime failure");
        auto q = frc_request_init(FRC_QUERY_CONJUGATE, "manger");
        q.person = FRC_PERSON_FIRST_PLURAL_MASCULINE;
        frc_response *bad = nullptr;
        if (frc_query(c.native_handle(), &q, &bad) != FRC_INVALID_ARGUMENT || bad)
            throw std::runtime_error("Invalid scope accepted");
        std::cout << count << " C/C++ typed and callback cases passed\n";
    } catch (const std::exception &error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
