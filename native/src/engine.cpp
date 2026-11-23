#include "frconjugation.h"
#include <unicode/normalizer2.h>
#include <unicode/brkiter.h>
#include <unicode/uchar.h>
#include <unicode/utf8.h>
#include <algorithm>
#include <array>
#include <cstdlib>
#include <cstring>
#include <map>
#include <memory>
#include <optional>
#include <regex>
#include <stdexcept>
#include <string>
#include <vector>
#include "catalogue.inc"

namespace {
using Text = std::optional<std::string>;
constexpr uint32_t missing = UINT32_MAX;

std::vector<std::string> split(const std::string &text, char delimiter) {
    std::vector<std::string> result;
    size_t start = 0;
    for (;;) {
        auto end = text.find(delimiter, start);
        result.push_back(text.substr(start, end - start));
        if (end == std::string::npos)
            return result;
        start = end + 1;
    }
}
icu::UnicodeString unicode(const std::string &value) {
    if (value.size() > INT32_MAX)
        throw std::invalid_argument("Input too long");
    int32_t at = 0, length = static_cast<int32_t>(value.size());
    while (at < length) {
        UChar32 scalar;
        U8_NEXT(value.data(), at, length, scalar);
        if (scalar < 0)
            throw std::invalid_argument("Invalid UTF-8");
    }
    return icu::UnicodeString::fromUTF8(value);
}
std::string utf8(const icu::UnicodeString &value) {
    std::string result;
    value.toUTF8String(result);
    return result;
}
std::string nfc(const std::string &value) {
    UErrorCode error = U_ZERO_ERROR;
    auto normalizer = icu::Normalizer2::getNFCInstance(error);
    icu::UnicodeString result;
    normalizer->normalize(unicode(value), result, error);
    if (U_FAILURE(error))
        throw std::runtime_error("Unicode normalization failed");
    return utf8(result);
}
Text normalized_input(const std::string &value) {
    auto input = unicode(value);
    int32_t begin = 0, end = input.length();
    while (begin < end && u_isUWhiteSpace(input.char32At(begin)))
        begin = input.moveIndex32(begin, 1);
    while (end > begin && u_isUWhiteSpace(input.char32At(input.moveIndex32(end, -1))))
        end = input.moveIndex32(end, -1);
    input.truncate(end);
    input.remove(0, begin);
    input.toLower(icu::Locale::getRoot());
    auto result = nfc(utf8(input));
    auto scalars = unicode(result);
    const auto alphabet = unicode(" '-12;_abcdefghijklmnopqrstuvwxyzâçèéêîïôûœ");
    if (result.empty())
        return {};
    for (int32_t i = 0; i < scalars.length(); i = scalars.moveIndex32(i, 1))
        if (alphabet.indexOf(scalars.char32At(i)) < 0)
            return {};
    return result;
}
std::pair<std::string, std::string> lemma_index(const std::string &key) {
    auto at = key.rfind('_');
    if (at != std::string::npos && at > 0 && at + 1 < key.size()) {
        auto index = key.substr(at + 1);
        if (index.find_first_not_of("0123456789") == std::string::npos)
            return {key.substr(0, at), index};
    }
    return {key, ""};
}
std::string spelling(const std::string &raw, frc_spelling which) {
    if (which == FRC_ALL)
        return raw;
    auto at = raw.find(';');
    if (which == FRC_PRIMARY)
        return raw.substr(0, at);
    return at == std::string::npos ? raw : raw.substr(at + 1);
}
std::string main_word(const std::string &form) {
    auto value = unicode(nfc(form));
    int32_t end = value.length();
    while (end > 0 && u_isUWhiteSpace(value.char32At(value.moveIndex32(end, -1))))
        end = value.moveIndex32(end, -1);
    int32_t start = end;
    while (start > 0 && !u_isUWhiteSpace(value.char32At(value.moveIndex32(start, -1))))
        start = value.moveIndex32(start, -1);
    auto word = utf8(value.tempSubStringBetween(start, end));
    static const std::regex trailing(
        "-(?:(?:m|t)(?:'|’)en|moi|toi|nous|vous|le|la|les|lui|leur|en|y)(?:-(?:en|y))?$");
    static const std::regex leading("^(?:(?:j|m|t|s|n|l|qu)(?:'|’))+");
    return std::regex_replace(std::regex_replace(word, trailing, ""), leading, "");
}
std::string common(const std::string &left, const std::string &right) {
    auto a = unicode(left), b = unicode(right);
    UErrorCode error = U_ZERO_ERROR;
    std::unique_ptr<icu::BreakIterator> ai(
        icu::BreakIterator::createCharacterInstance(icu::Locale::getRoot(), error));
    std::unique_ptr<icu::BreakIterator> bi(
        icu::BreakIterator::createCharacterInstance(icu::Locale::getRoot(), error));
    if (U_FAILURE(error))
        throw std::runtime_error("Unicode segmentation failed");
    ai->setText(a);
    bi->setText(b);
    int32_t previousA = ai->first(), previousB = bi->first();
    for (;;) {
        int32_t nextA = ai->next(), nextB = bi->next();
        if (nextA == icu::BreakIterator::DONE || nextB == icu::BreakIterator::DONE)
            break;
        if (a.tempSubStringBetween(previousA, nextA) != b.tempSubStringBetween(previousB, nextB))
            break;
        previousA = nextA;
        previousB = nextB;
    }
    return utf8(a.tempSubStringBetween(0, previousA));
}

struct Operation {
    std::string prefix;
    uint32_t trim;
    std::string suffix;
};
struct Entry {
    uint32_t flags;
    Text variant;
    uint32_t model;
};
struct Catalogue {
    std::vector<std::string> slots, keys;
    std::map<std::string, size_t> slot_ids;
    std::map<std::string, Entry> entries;
    std::map<std::string, std::vector<int>> homonyms;
    std::map<std::string, uint32_t> suffixes;
    std::vector<std::vector<uint32_t>> templates;
    std::vector<std::array<uint32_t, 16>> blocks;
    std::vector<std::vector<Operation>> programs;
    std::vector<uint32_t> fallbacks;

    // Only the compile-time embedded, trusted catalogue is accepted.
    Catalogue() {
        auto word = [](size_t at) {
            if (at > sizeof(catalogue_bytes) - 4)
                throw std::runtime_error("Invalid catalogue offset");
            return uint32_t(catalogue_bytes[at]) | uint32_t(catalogue_bytes[at + 1]) << 8 |
                   uint32_t(catalogue_bytes[at + 2]) << 16 |
                   uint32_t(catalogue_bytes[at + 3]) << 24;
        };
        if (std::memcmp(catalogue_bytes, "FCR1", 4) || word(4) != 1)
            throw std::runtime_error("Invalid catalogue header");
        std::array<size_t, 8> sections{};
        for (size_t i = 0; i < 8; ++i)
            sections[i] = word(8 + i * 4);
        if (sections[0] != 40 || sections[7] != sizeof(catalogue_bytes) ||
            !std::is_sorted(sections.begin(), sections.end()))
            throw std::runtime_error("Invalid catalogue directory");
        auto record = [&](size_t section, size_t index) {
            size_t base = sections.at(section), count = word(base);
            if (index >= count)
                throw std::runtime_error("Invalid catalogue record");
            size_t payload = base + 8 + count * 4;
            size_t begin = payload + word(base + 4 + index * 4);
            size_t end = payload + word(base + 8 + index * 4);
            if (begin > end || end > sections.at(section + 1))
                throw std::runtime_error("Invalid catalogue record range");
            return std::make_pair(begin, end);
        };
        std::vector<std::string> strings;
        for (size_t i = 0; i < word(sections[0]); ++i) {
            auto range = record(0, i);
            strings.emplace_back(reinterpret_cast<const char *>(catalogue_bytes + range.first),
                                 range.second - range.first);
        }
        for (size_t at = sections[1]; at < sections[2]; at += 4) {
            slots.push_back(strings.at(word(at)));
            slot_ids.emplace(slots.back(), slots.size() - 1);
        }
        if (slots.empty())
            throw std::runtime_error("No catalogue slots");
        for (size_t at = sections[3]; at < sections[4]; at += 8)
            suffixes.emplace(strings.at(word(at)), word(at + 4));
        const size_t width = (slots.size() + 15) / 16;
        for (size_t at = sections[4]; at < sections[5]; at += width * 4) {
            std::vector<uint32_t> row;
            for (size_t i = 0; i < width; ++i)
                row.push_back(word(at + i * 4));
            templates.push_back(std::move(row));
        }
        for (size_t at = sections[5]; at < sections[6]; at += 64) {
            std::array<uint32_t, 16> row{};
            for (size_t i = 0; i < 16; ++i)
                row[i] = word(at + i * 4);
            blocks.push_back(row);
        }
        for (size_t i = 0; i < word(sections[6]); ++i) {
            auto range = record(6, i);
            std::vector<Operation> row;
            for (size_t at = range.first; at < range.second; at += 12)
                row.push_back({strings.at(word(at)), word(at + 4), strings.at(word(at + 8))});
            programs.push_back(std::move(row));
        }
        std::map<uint32_t, size_t> frequencies;
        for (size_t at = sections[2]; at < sections[3]; at += 12) {
            auto key = strings.at(word(at));
            auto matches = models(key);
            if (matches.empty())
                throw std::runtime_error("Missing lexical model");
            Text variant;
            if (word(at + 8) != missing)
                variant = strings.at(word(at + 8));
            entries.emplace(key, Entry{word(at + 4), variant, matches.front()});
            keys.push_back(key);
            ++frequencies[matches.front()];
            auto parts = lemma_index(key);
            if (!parts.second.empty())
                homonyms[parts.first].push_back(std::stoi(parts.second));
        }
        for (auto &item : homonyms)
            std::sort(item.second.begin(), item.second.end());
        std::vector<uint32_t> ranked;
        for (const auto &item : frequencies)
            ranked.push_back(item.first);
        std::sort(ranked.begin(), ranked.end(), [&](auto a, auto b) {
            if (frequencies[a] != frequencies[b])
                return frequencies[a] > frequencies[b];
            return a < b;
        });
        for (size_t slot = 0; slot < slots.size(); ++slot) {
            auto found = std::find_if(ranked.begin(), ranked.end(),
                                      [&](auto model) { return program(model, slot) != 0; });
            if (found == ranked.end())
                throw std::runtime_error("Missing fallback model");
            fallbacks.push_back(*found);
        }
    }
    uint32_t program(uint32_t model, size_t slot) const {
        return blocks.at(templates.at(model).at(slot / 16)).at(slot % 16);
    }
    std::vector<uint32_t> models(const std::string &key) const {
        auto parts = lemma_index(key);
        std::string marked = "^" + parts.second + "|" + parts.first;
        std::vector<uint32_t> result;
        for (size_t at = 0;;) {
            auto match = suffixes.find(marked.substr(at));
            if (match != suffixes.end())
                result.push_back(match->second);
            if (at == marked.size())
                break;
            ++at;
            while (at < marked.size() && (static_cast<unsigned char>(marked[at]) & 0xc0) == 0x80)
                ++at;
        }
        return result;
    }
    std::string resolve(const std::string &input, int homonym) const {
        if (entries.count(input))
            return input;
        auto found = homonyms.find(input);
        if (found != homonyms.end())
            return input + "_" + std::to_string(homonym == 0 ? found->second.front() : homonym);
        return input;
    }
    Text render(uint32_t model, size_t slot, const std::string &lemma,
                bool fallback = false) const {
        uint32_t id = program(model, slot);
        if (!id)
            return {};
        auto text = unicode(lemma);
        int32_t length = text.countChar32();
        std::string result;
        bool first = true;
        for (const auto &operation : programs.at(id)) {
            std::string retained;
            if (operation.trim != missing) {
                if (operation.trim > static_cast<uint32_t>(length)) {
                    if (!fallback)
                        return {};
                    retained = lemma;
                } else
                    retained = utf8(
                        text.tempSubStringBetween(0, text.moveIndex32(0, length - operation.trim)));
            }
            if (!first)
                result += ";";
            first = false;
            result += operation.prefix + retained + operation.suffix;
        }
        if (fallback && result.empty())
            return lemma;
        return result;
    }
    Text raw(const std::string &input, size_t slot, int homonym, frc_mode mode) const {
        if (mode != FRC_INFERRED) {
            auto key = resolve(nfc(input), homonym);
            auto entry = entries.find(key);
            if (entry != entries.end()) {
                auto answer = render(entry->second.model, slot, lemma_index(key).first);
                if (answer)
                    return answer;
            }
            if (mode == FRC_CATALOGUE)
                return {};
        }
        auto normalized = normalized_input(input);
        if (!normalized)
            return {};
        auto key = resolve(*normalized, homonym);
        auto lemma = lemma_index(key).first;
        for (auto model : models(key)) {
            auto answer = render(model, slot, lemma);
            if (answer && !answer->empty())
                return answer;
        }
        return render(fallbacks.at(slot), slot, lemma, true);
    }
    Text prefix(const std::string &input, int homonym, frc_mode mode) const {
        Text result;
        for (size_t slot = 0; slot < slots.size(); ++slot) {
            auto answer = raw(input, slot, homonym, mode);
            if (!answer)
                continue;
            for (const auto &alternative : split(*answer, ';')) {
                auto word = main_word(alternative);
                if (word.empty())
                    continue;
                result = result ? common(*result, word) : word;
                if (result->empty())
                    return result;
            }
        }
        return result;
    }
    Text pronoun(const std::string &input, const std::string &label, int homonym,
                 const std::string &form) const {
        auto parts = split(label, '|');
        if (parts.size() != 4 || parts[1] == "imperatif" || parts[1] == "participe")
            return {};
        static const std::map<std::string, std::string> subjects = {
            {"1sm", "je"},   {"1sf", "je"},  {"2sm", "tu"},   {"2sf", "tu"},   {"3sm", "il"},
            {"3sf", "elle"}, {"3sn", "on"},  {"1pm", "nous"}, {"1pf", "nous"}, {"2pm", "vous"},
            {"2pf", "vous"}, {"3pm", "ils"}, {"3pf", "elles"}};
        auto subject = subjects.find(parts[3]);
        if (subject == subjects.end())
            return {};
        auto found = entries.find(resolve(nfc(input), homonym));
        uint32_t flags = found == entries.end() ? 0 : found->second.flags;
        auto text = unicode(form);
        UChar32 first = text.isEmpty() ? 0 : u_tolower(text.char32At(0));
        bool vowel = unicode("aeiouàâéèêëîïôùûüœæy").indexOf(first) >= 0;
        if (first == 'h')
            vowel = (flags & 1) == 0;
        bool simple = parts[2] == "present" || parts[2] == "imparfait" ||
                      parts[2] == "passe_simple" || parts[2] == "futur_simple";
        if (parts[0] != "voix_passive" && simple && (flags & 2))
            vowel = false;
        std::string result = subject->second == "je" && vowel ? "j'" : subject->second + " ";
        if (parts[1] == "subjonctif")
            result = (parts[3][0] == '3' ? "qu'" : "que ") + result;
        return result;
    }
};
std::shared_ptr<const Catalogue> bundled() {
    static auto catalogue = std::make_shared<const Catalogue>();
    return catalogue;
}
char *copy_string(const std::string &text) {
    auto result = static_cast<char *>(std::malloc(text.size() + 1));
    if (!result)
        throw std::bad_alloc();
    std::memcpy(result, text.c_str(), text.size() + 1);
    return result;
}
template <class Function> frc_status string_result(char **out, Function function) noexcept {
    if (!out)
        return FRC_INVALID_ARGUMENT;
    *out = nullptr;
    try {
        auto value = function();
        if (!value)
            return FRC_MISSING;
        *out = copy_string(*value);
        return FRC_OK;
    } catch (const std::invalid_argument &) {
        return FRC_INVALID_ARGUMENT;
    } catch (...) {
        return FRC_ERROR;
    }
}
void check(bool valid) {
    if (!valid)
        throw std::invalid_argument("Invalid argument");
}
void check_query(const frc_engine *engine, const char *verb, int homonym, frc_mode mode) {
    check(engine && verb && homonym >= 0 && mode >= FRC_CATALOGUE && mode <= FRC_GUESS);
    unicode(verb);
}
} // namespace

struct frc_engine {
    std::shared_ptr<const Catalogue> catalogue = bundled();
};
extern "C" {
frc_status frc_create(frc_engine **out) {
    if (!out)
        return FRC_INVALID_ARGUMENT;
    *out = nullptr;
    try {
        *out = new frc_engine;
        return FRC_OK;
    } catch (...) {
        return FRC_ERROR;
    }
}
void frc_destroy(frc_engine *engine) {
    delete engine;
}
void frc_string_free(char *value) {
    std::free(value);
}
size_t frc_slot_count(const frc_engine *engine) {
    return engine ? engine->catalogue->slots.size() : 0;
}
size_t frc_entry_count(const frc_engine *engine) {
    return engine ? engine->catalogue->keys.size() : 0;
}
frc_status frc_slot_name(const frc_engine *engine, size_t index, char **out) {
    return string_result(out, [&]() -> Text {
        check(engine && index < frc_slot_count(engine));
        return engine->catalogue->slots.at(index);
    });
}
frc_status frc_entry(const frc_engine *engine, size_t index, char **key, uint32_t *flags,
                     char **variant) {
    if (key)
        *key = nullptr;
    if (variant)
        *variant = nullptr;
    if (flags)
        *flags = 0;
    if (!engine || !key || !flags || !variant || key == variant || index >= frc_entry_count(engine))
        return FRC_INVALID_ARGUMENT;
    try {
        const auto &name = engine->catalogue->keys.at(index);
        const auto &entry = engine->catalogue->entries.at(name);
        std::unique_ptr<char, decltype(&std::free)> name_copy(copy_string(name), std::free);
        if (entry.variant)
            *variant = copy_string(*entry.variant);
        *key = name_copy.release();
        *flags = entry.flags;
        return FRC_OK;
    } catch (...) {
        return FRC_ERROR;
    }
}
frc_status frc_form(const frc_engine *engine, const char *verb, const char *slot, int homonym,
                    frc_mode mode, frc_spelling which, char **out) {
    return string_result(out, [&]() -> Text {
        check_query(engine, verb, homonym, mode);
        check(slot && which >= FRC_PRIMARY && which <= FRC_ALL);
        const auto &catalogue = *engine->catalogue;
        auto found = catalogue.slot_ids.find(slot);
        if (found == catalogue.slot_ids.end())
            return {};
        auto value = catalogue.raw(verb, found->second, homonym, mode);
        if (!value)
            return {};
        // Swift inference returns alternatives. Catalogue-first guessing keeps
        // primary catalogue answers and raw inferred alternatives.
        if (mode == FRC_INFERRED)
            return *value;
        if (mode == FRC_GUESS && !catalogue.raw(verb, found->second, homonym, FRC_CATALOGUE))
            return *value;
        return spelling(*value, which);
    });
}
frc_status frc_common_prefix(const frc_engine *engine, const char *verb, int homonym, frc_mode mode,
                             char **out) {
    return string_result(out, [&]() -> Text {
        check_query(engine, verb, homonym, mode);
        return engine->catalogue->prefix(verb, homonym, mode);
    });
}
frc_status frc_gerondif(const frc_engine *engine, const char *verb, const char *voice,
                        const char *tense, int homonym, frc_mode mode, char **out) {
    return string_result(out, [&]() -> Text {
        check_query(engine, verb, homonym, mode);
        check(voice && tense);
        static const std::map<std::string, std::string> sources = {
            {"gerondif_present", "present"},
            {"gerondif_passe_sm", "passe_compound_sm"},
            {"gerondif_passe_sf", "passe_compound_sf"},
            {"gerondif_passe_pm", "passe_compound_pm"},
            {"gerondif_passe_pf", "passe_compound_pf"}};
        auto source = sources.find(tense);
        if (source == sources.end())
            return {};
        const auto &catalogue = *engine->catalogue;
        auto slot =
            catalogue.slot_ids.find(std::string(voice) + "|participe|" + source->second + "|-");
        if (slot == catalogue.slot_ids.end())
            return {};
        if (mode != FRC_INFERRED) {
            auto known = catalogue.raw(verb, slot->second, homonym, FRC_CATALOGUE);
            if (known)
                return "en " + spelling(*known, FRC_PRIMARY);
        }
        auto value = catalogue.raw(verb, slot->second, homonym, mode);
        if (!value)
            return {};
        std::string result;
        for (const auto &alternative : split(*value, ';')) {
            if (!result.empty())
                result += ";";
            result += "en " + alternative;
        }
        return result;
    });
}
frc_status frc_pronoun(const frc_engine *engine, const char *verb, const char *slot, int homonym,
                       frc_spelling which, char **out) {
    return string_result(out, [&]() -> Text {
        check_query(engine, verb, homonym, FRC_CATALOGUE);
        check(slot && which >= FRC_PRIMARY && which <= FRC_ALTERNATIVE);
        const auto &catalogue = *engine->catalogue;
        auto found = catalogue.slot_ids.find(slot);
        if (found == catalogue.slot_ids.end())
            return {};
        auto form = catalogue.raw(verb, found->second, homonym, FRC_CATALOGUE);
        if (!form)
            return {};
        return catalogue.pronoun(verb, slot, homonym, spelling(*form, which));
    });
}
frc_status frc_with_pronoun(const frc_engine *engine, const char *verb, const char *slot,
                            int homonym, frc_spelling which, char **out) {
    return string_result(out, [&]() -> Text {
        check_query(engine, verb, homonym, FRC_CATALOGUE);
        check(slot && which >= FRC_PRIMARY && which <= FRC_ALTERNATIVE);
        const auto &catalogue = *engine->catalogue;
        auto found = catalogue.slot_ids.find(slot);
        if (found == catalogue.slot_ids.end())
            return {};
        auto form = catalogue.raw(verb, found->second, homonym, FRC_CATALOGUE);
        if (!form)
            return {};
        auto selected = spelling(*form, which);
        return catalogue.pronoun(verb, slot, homonym, selected).value_or("") + selected;
    });
}
}
