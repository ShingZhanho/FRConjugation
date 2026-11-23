#include "frconjugation.hpp"
#include <cstdlib>
#include <cstdio>
#include <iostream>

static void emit(const std::optional<std::string> &value) {
    uint32_t size = value ? static_cast<uint32_t>(value->size()) : UINT32_MAX;
    unsigned char bytes[4] = {
        static_cast<unsigned char>(size), static_cast<unsigned char>(size >> 8),
        static_cast<unsigned char>(size >> 16), static_cast<unsigned char>(size >> 24)};
    if (std::fwrite(bytes, 1, 4, stdout) != 4)
        std::abort();
    if (value && std::fwrite(value->data(), 1, value->size(), stdout) != value->size())
        std::abort();
}
int main() {
    frconjugation::Conjugator c;
    auto slots = c.slots();
    for (const auto &slot : slots)
        emit(slot);
    for (size_t i = 0; i < frc_entry_count(c.native_handle()); ++i) {
        char *key = nullptr, *variant = nullptr;
        uint32_t flags = 0;
        if (frc_entry(c.native_handle(), i, &key, &flags, &variant) != FRC_OK)
            return 1;
        std::string verb(key);
        emit(verb);
        emit(std::to_string(flags));
        emit(variant ? std::optional<std::string>(variant) : std::nullopt);
        frc_string_free(key);
        frc_string_free(variant);
        for (const auto &slot : slots)
            emit(c.form(verb, slot, FRC_CATALOGUE, 0, FRC_ALL));
    }
    for (const auto &verb : {"blorper", "x", "er", "_", "manger", "finir", "pleuvoir", "aller",
                             "ressortir_2", "réinventer", "télétravailler"})
        for (const auto &slot : slots)
            emit(c.form(verb, slot, FRC_INFERRED));
}
