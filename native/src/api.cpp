#include "frconjugation_api.h"
#include <unicode/normalizer2.h>
#include <unicode/uchar.h>
#include <algorithm>
#include <map>
#include <memory>
#include <optional>
#include <set>
#include <stdexcept>
#include <string>
#include <thread>
#include <vector>

struct frc_response {
    std::optional<std::string> text;
    size_t number = 0;
    std::vector<std::string> strings;
    std::vector<int> values;
    std::vector<std::string> row_text;
    std::vector<frc_form_row> rows;
};
namespace {
using Text = std::optional<std::string>;
void check(bool valid) {
    if (!valid)
        throw std::invalid_argument("Invalid request");
}
Text take(frc_status status, char *text) {
    std::unique_ptr<char, decltype(&frc_string_free)> owner(text, frc_string_free);
    if (status == FRC_MISSING)
        return {};
    if (status == FRC_INVALID_ARGUMENT)
        throw std::invalid_argument("Invalid query");
    if (status != FRC_OK)
        throw std::runtime_error("Query failed");
    return text ? Text(text) : Text();
}
std::vector<std::string> split(const std::string &s) {
    std::vector<std::string> parts;
    size_t start = 0;
    for (;;) {
        auto at = s.find('|', start);
        parts.push_back(s.substr(start, at - start));
        if (at == s.npos)
            return parts;
        start = at + 1;
    }
}
std::string normalize(const std::string &s, bool fold = false) {
    UErrorCode error = U_ZERO_ERROR;
    auto normalizer =
        fold ? icu::Normalizer2::getNFKDInstance(error) : icu::Normalizer2::getNFCInstance(error);
    auto value = icu::UnicodeString::fromUTF8(s);
    if (fold) {
        value.findAndReplace(icu::UnicodeString::fromUTF8("œ"), "oe");
        value.findAndReplace(icu::UnicodeString::fromUTF8("æ"), "ae");
    }
    icu::UnicodeString output;
    normalizer->normalize(value, output, error);
    if (U_FAILURE(error))
        throw std::runtime_error("Normalization failed");
    if (fold)
        for (int32_t i = output.length(); i > 0;) {
            i = output.moveIndex32(i, -1);
            auto c = output.char32At(i);
            if (u_charType(c) == U_NON_SPACING_MARK)
                output.remove(i, U16_LENGTH(c));
        }
    std::string result;
    output.toUTF8String(result);
    return result;
}
std::pair<std::string, int> lemma(const std::string &key) {
    auto at = key.rfind('_');
    if (at != key.npos && at > 0 && at + 1 < key.size() &&
        key.find_first_not_of("0123456789", at + 1) == key.npos)
        return {key.substr(0, at), std::stoi(key.substr(at + 1))};
    return {key, 0};
}
struct Entry {
    unsigned flags;
    Text variant;
};
struct Index {
    std::map<std::string, Entry> entries;
    std::map<std::string, std::vector<int>> homonyms;
    std::vector<std::string> verbs;
    std::vector<std::pair<std::string, frc_form_row>> slots;
    Index() {
        frc_engine *raw = nullptr;
        check(frc_create(&raw) == FRC_OK);
        std::unique_ptr<frc_engine, decltype(&frc_destroy)> engine(raw, frc_destroy);
        std::set<std::string> bases;
        for (size_t i = 0; i < frc_entry_count(raw); ++i) {
            char *key = nullptr, *variant = nullptr;
            uint32_t flags = 0;
            auto status = frc_entry(raw, i, &key, &flags, &variant);
            std::unique_ptr<char, decltype(&frc_string_free)> v(variant, frc_string_free);
            auto name = take(status, key).value();
            entries.emplace(name, Entry{flags, variant ? Text(variant) : Text()});
            auto part = lemma(name);
            bases.insert(part.first);
            if (part.second)
                homonyms[part.first].push_back(part.second);
        }
        for (auto &item : homonyms)
            std::sort(item.second.begin(), item.second.end());
        verbs.assign(bases.begin(), bases.end());
        std::map<std::string, std::string> keys;
        for (auto &v : verbs)
            keys[v] = normalize(v, true);
        std::sort(verbs.begin(), verbs.end(), [&](const auto &a, const auto &b) {
            return keys[a] == keys[b] ? a < b : keys[a] < keys[b];
        });
        for (size_t i = 0; i < frc_slot_count(raw); ++i) {
            char *text = nullptr;
            auto status = frc_slot_name(raw, i, &text);
            auto name = take(status, text).value();
            auto p = split(name);
            frc_form_row row{FRC_VOICE_ANY, FRC_MOOD_ANY, FRC_TENSE_ANY, FRC_PERSON_ANY, nullptr};
            for (int v = 0; frc_voice_label(static_cast<frc_voice>(v)); ++v)
                if (p[0] == frc_voice_label(static_cast<frc_voice>(v)))
                    row.voice = static_cast<frc_voice>(v);
            for (int m = 0; frc_mood_label(static_cast<frc_mood>(m)); ++m)
                if (p[1] == frc_mood_label(static_cast<frc_mood>(m)))
                    row.mood = static_cast<frc_mood>(m);
            for (int t = 0; frc_tense_label(static_cast<frc_tense>(t)); ++t)
                if (p[2] == frc_tense_label(static_cast<frc_tense>(t)))
                    row.tense = static_cast<frc_tense>(t);
            for (int person = 0; frc_person_label(static_cast<frc_person>(person)); ++person)
                if (p[3] == frc_person_label(static_cast<frc_person>(person)))
                    row.person = static_cast<frc_person>(person);
            slots.emplace_back(name, row);
        }
    }
};
const Index &index() {
    static const Index value;
    return value;
}
Text form(const frc_engine *engine, const frc_request &q, const std::string &slot,
          frc_spelling spelling) {
    char *text = nullptr;
    auto status = frc_form(engine, q.verb, slot.c_str(), q.homonym, q.prediction, spelling, &text);
    return take(status, text);
}
} // namespace
extern "C" {
frc_request frc_request_init(frc_operation operation, const char *verb) {
    return {operation,      verb, FRC_VOICE_ANY, FRC_MOOD_ANY, FRC_TENSE_ANY,
            FRC_PERSON_ANY, 0,    FRC_CATALOGUE, FRC_PRIMARY};
}
frc_status frc_query(const frc_engine *engine, const frc_request *request, frc_response **out) {
    if (!out)
        return FRC_INVALID_ARGUMENT;
    *out = nullptr;
    try {
        check(engine && request && request->verb);
        const auto &q = *request;
        check(q.homonym >= 0 && q.prediction >= FRC_CATALOGUE && q.prediction <= FRC_GUESS &&
              q.spelling >= FRC_PRIMARY && q.spelling <= FRC_ALL);
        check((q.voice == FRC_VOICE_ANY || frc_voice_label(q.voice)) &&
              (q.mood == FRC_MOOD_ANY || frc_mood_label(q.mood)) &&
              (q.tense == FRC_TENSE_ANY || frc_tense_label(q.tense)) &&
              (q.person == FRC_PERSON_ANY || frc_person_label(q.person)));
        const auto &idx = index();
        auto result = std::make_unique<frc_response>();
        auto key = normalize(q.verb);
        auto hi = idx.homonyms.find(key);
        auto ei = idx.entries.find(key);
        if (q.operation >= FRC_QUERY_ALL_VERBS) {
            switch (q.operation) {
            case FRC_QUERY_ALL_VERBS:
                result->strings = idx.verbs;
                break;
            case FRC_QUERY_VERB_COUNT:
                result->number = idx.verbs.size();
                break;
            case FRC_QUERY_HAS_VERB:
                result->number = ei != idx.entries.end() || hi != idx.homonyms.end();
                break;
            case FRC_QUERY_HAS_HOMONYMS:
                result->number = hi != idx.homonyms.end();
                break;
            case FRC_QUERY_HOMONYM_COUNT:
                result->number = hi == idx.homonyms.end() ? 1 : hi->second.size();
                break;
            case FRC_QUERY_HOMONYM_INDICES:
                if (hi != idx.homonyms.end())
                    result->values = hi->second;
                break;
            case FRC_QUERY_IS_H_ASPIRE:
                result->number = ei != idx.entries.end() && (ei->second.flags & 1);
                break;
            case FRC_QUERY_BLOCKS_ELISION:
                if (ei == idx.entries.end() && hi != idx.homonyms.end())
                    ei = idx.entries.find(
                        key + "_" + std::to_string(q.homonym ? q.homonym : hi->second.front()));
                result->number = ei != idx.entries.end() && (ei->second.flags & 2);
                break;
            case FRC_QUERY_IS_1990_REFORM:
                result->number = ei != idx.entries.end() && (ei->second.flags & 4);
                break;
            case FRC_QUERY_REFORM_VARIANT:
                if (ei == idx.entries.end() || !ei->second.variant)
                    return FRC_MISSING;
                result->text = ei->second.variant;
                break;
            default:
                throw std::invalid_argument("Unknown operation");
            }
        } else if (q.operation == FRC_QUERY_PREFIX || q.operation == FRC_QUERY_GERONDIF) {
            char *text = nullptr;
            frc_status status;
            if (q.operation == FRC_QUERY_PREFIX)
                status = frc_common_prefix(engine, q.verb, q.homonym, q.prediction, &text);
            else {
                check(q.voice != FRC_VOICE_ANY && q.tense != FRC_TENSE_ANY);
                status = frc_gerondif(engine, q.verb, frc_voice_label(q.voice),
                                      frc_tense_label(q.tense), q.homonym, q.prediction, &text);
            }
            result->text = take(status, text);
            if (!result->text)
                return FRC_MISSING;
        } else if (q.operation == FRC_QUERY_PRONOUN || q.operation == FRC_QUERY_WITH_PRONOUN ||
                   q.operation == FRC_QUERY_HAS_ALTERNATIVE_FORM ||
                   q.operation == FRC_QUERY_HAS_ALTERNATIVE_PARTICIPLE ||
                   q.operation == FRC_QUERY_PARTICIPLE) {
            check(q.voice != FRC_VOICE_ANY && q.tense != FRC_TENSE_ANY);
            bool part = q.operation == FRC_QUERY_PARTICIPLE ||
                        q.operation == FRC_QUERY_HAS_ALTERNATIVE_PARTICIPLE;
            check(part || (q.mood != FRC_MOOD_ANY && q.person != FRC_PERSON_ANY));
            std::string slot = std::string(frc_voice_label(q.voice)) + "|" +
                               (part ? "participe" : frc_mood_label(q.mood)) + "|" +
                               frc_tense_label(q.tense) + "|" +
                               (part ? "-" : frc_person_label(q.person));
            if (q.operation == FRC_QUERY_HAS_ALTERNATIVE_FORM ||
                q.operation == FRC_QUERY_HAS_ALTERNATIVE_PARTICIPLE) {
                auto copy = q;
                copy.prediction = FRC_CATALOGUE;
                auto value = form(engine, copy, slot, FRC_ALL);
                result->number = value && value->find(';') != std::string::npos;
            } else if (part) {
                result->text = form(engine, q, slot, q.spelling);
                if (!result->text)
                    return FRC_MISSING;
            } else {
                char *text = nullptr;
                auto status =
                    q.operation == FRC_QUERY_PRONOUN
                        ? frc_pronoun(engine, q.verb, slot.c_str(), q.homonym, q.spelling, &text)
                        : frc_with_pronoun(engine, q.verb, slot.c_str(), q.homonym, q.spelling,
                                           &text);
                result->text = take(status, text);
                if (!result->text)
                    return FRC_MISSING;
            }
        } else {
            check(q.operation == FRC_QUERY_CONJUGATE || q.operation == FRC_QUERY_PARTICIPLES ||
                  (q.operation >= FRC_QUERY_VOICES && q.operation <= FRC_QUERY_PERSONS));
            bool structure = q.operation >= FRC_QUERY_VOICES;
            if (q.operation == FRC_QUERY_CONJUGATE)
                check((q.voice != FRC_VOICE_ANY || q.mood == FRC_MOOD_ANY) &&
                      (q.mood != FRC_MOOD_ANY || q.tense == FRC_TENSE_ANY) &&
                      (q.tense != FRC_TENSE_ANY || q.person == FRC_PERSON_ANY));
            if (q.operation == FRC_QUERY_PARTICIPLES || q.operation >= FRC_QUERY_MODES)
                check(q.voice != FRC_VOICE_ANY);
            if (q.operation >= FRC_QUERY_TENSES)
                check(q.mood != FRC_MOOD_ANY);
            if (q.operation == FRC_QUERY_PERSONS)
                check(q.tense != FRC_TENSE_ANY);
            std::map<std::string, int> ordered;
            std::map<int, std::string> person_forms;
            for (const auto &item : idx.slots) {
                const auto &row = item.second;
                if (q.voice != FRC_VOICE_ANY && row.voice != q.voice)
                    continue;
                if (q.mood != FRC_MOOD_ANY && row.mood != q.mood)
                    continue;
                if (q.tense != FRC_TENSE_ANY && row.tense != q.tense)
                    continue;
                if (q.person != FRC_PERSON_ANY && row.person != q.person)
                    continue;
                if (q.operation == FRC_QUERY_CONJUGATE && row.person == FRC_PERSON_ANY)
                    continue;
                if (q.operation == FRC_QUERY_PARTICIPLES && row.mood != FRC_MOOD_PARTICIPE)
                    continue;
                if (q.operation == FRC_QUERY_PERSONS && row.person == FRC_PERSON_ANY)
                    continue;
                auto copy = q;
                if (structure)
                    copy.prediction = FRC_CATALOGUE;
                auto value = form(engine, copy, item.first, structure ? FRC_ALL : q.spelling);
                if (!value)
                    continue;
                if (structure) {
                    switch (q.operation) {
                    case FRC_QUERY_VOICES:
                        ordered[frc_voice_label(row.voice)] = row.voice;
                        break;
                    case FRC_QUERY_MODES:
                        ordered[frc_mood_label(row.mood)] = row.mood;
                        break;
                    case FRC_QUERY_TENSES:
                        ordered[frc_tense_label(row.tense)] = row.tense;
                        break;
                    default:
                        person_forms[row.person] = *value;
                        break;
                    }
                } else {
                    result->row_text.push_back(*value);
                    result->rows.push_back(row);
                }
            }
            if (q.operation == FRC_QUERY_PERSONS) {
                std::vector<std::string> order;
                std::map<std::string, std::vector<int>> groups;
                for (auto &item : person_forms) {
                    if (!groups.count(item.second))
                        order.push_back(item.second);
                    groups[item.second].push_back(item.first);
                }
                for (auto &raw : order)
                    result->values.insert(result->values.end(), groups[raw].begin(),
                                          groups[raw].end());
            } else
                for (auto &item : ordered)
                    result->values.push_back(item.second);
            for (size_t i = 0; i < result->rows.size(); ++i)
                result->rows[i].text = result->row_text[i].c_str();
            if (q.operation == FRC_QUERY_CONJUGATE && q.person != FRC_PERSON_ANY) {
                if (result->row_text.empty())
                    return FRC_MISSING;
                result->text = result->row_text.front();
            }
            if (q.operation == FRC_QUERY_CONJUGATE && q.voice == FRC_VOICE_ANY &&
                result->rows.empty())
                return FRC_MISSING;
        }
        *out = result.release();
        return FRC_OK;
    } catch (const std::invalid_argument &) {
        return FRC_INVALID_ARGUMENT;
    } catch (...) {
        return FRC_ERROR;
    }
}
void frc_response_free(frc_response *r) {
    delete r;
}
const char *frc_response_text(const frc_response *r) {
    return r && r->text ? r->text->c_str() : nullptr;
}
size_t frc_response_number(const frc_response *r) {
    return r ? r->number : 0;
}
size_t frc_response_row_count(const frc_response *r) {
    return r ? r->rows.size() : 0;
}
const frc_form_row *frc_response_row(const frc_response *r, size_t i) {
    return r && i < r->rows.size() ? &r->rows[i] : nullptr;
}
size_t frc_response_value_count(const frc_response *r) {
    return r ? r->values.size() : 0;
}
int frc_response_value(const frc_response *r, size_t i) {
    return r && i < r->values.size() ? r->values[i] : -1;
}
size_t frc_response_string_count(const frc_response *r) {
    return r ? r->strings.size() : 0;
}
const char *frc_response_string(const frc_response *r, size_t i) {
    return r && i < r->strings.size() ? r->strings[i].c_str() : nullptr;
}
frc_status frc_query_async(const frc_engine *engine, const frc_request *request,
                           frc_query_callback callback, void *context) {
    if (!engine || !request || !request->verb || !callback)
        return FRC_INVALID_ARGUMENT;
    try {
        std::string verb = request->verb;
        auto q = *request;
        std::thread([verb = std::move(verb), q, callback, context]() mutable {
            q.verb = verb.c_str();
            frc_engine *raw = nullptr;
            auto status = frc_create(&raw);
            std::unique_ptr<frc_engine, decltype(&frc_destroy)> owner(raw, frc_destroy);
            frc_response *response = nullptr;
            if (status == FRC_OK)
                status = frc_query(raw, &q, &response);
            callback(status, response, context);
        }).detach();
        return FRC_OK;
    } catch (...) {
        return FRC_ERROR;
    }
}
frc_status frc_create_async(frc_engine_callback callback, void *context) {
    if (!callback)
        return FRC_INVALID_ARGUMENT;
    try {
        std::thread([callback, context] {
            frc_engine *engine = nullptr;
            auto status = frc_create(&engine);
            callback(status, engine, context);
        }).detach();
        return FRC_OK;
    } catch (...) {
        return FRC_ERROR;
    }
}
frc_status frc_get_shared(frc_engine **out) {
    return frc_create(out);
}
frc_status frc_get_shared_async(frc_engine_callback callback, void *context) {
    return frc_create_async(callback, context);
}
}
