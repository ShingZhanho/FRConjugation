#include "frconjugation.hpp"
#include <fstream>
#include <iostream>
#include <set>
#include <sstream>

#include "fixtures.hpp"
int main(int argc, char **argv) {
    try {
        if (argc != 2)
            throw std::runtime_error("Expected fixture path");
        std::ifstream input(argv[1]);
        std::string line;
        std::getline(input, line);
        if (line != "id\toperation\tmode\tverb\tselector\thomonym\tspelling\texpected")
            throw std::runtime_error("Invalid fixture header");
        frconjugation::Conjugator conjugator;
        std::set<std::string> ids;
        while (std::getline(input, line)) {
            auto row = fields(line);
            if (row.size() != 8 || !ids.insert(row[0]).second)
                throw std::runtime_error("Invalid or duplicate fixture row");
            auto verb = decode(row[3]).value();
            auto selector = decode(row[4]).value();
            auto expected = decode(row[7]);
            const auto mode = row[2] == "catalogue"  ? FRC_CATALOGUE
                              : row[2] == "inferred" ? FRC_INFERRED
                                                     : FRC_GUESS;
            if (row[2] != "catalogue" && row[2] != "inferred" && row[2] != "guess")
                throw std::runtime_error("Invalid mode");
            if (row[6] != "primary" && row[6] != "alternative")
                throw std::runtime_error("Invalid spelling");
            auto spelling = row[6] == "primary" ? FRC_PRIMARY : FRC_ALTERNATIVE;
            int homonym = std::stoi(row[5]);
            char *text = nullptr;
            frc_status status;
            auto engine = conjugator.native_handle();
            if (row[1] == "form")
                status = frc_form(engine, verb.c_str(), selector.c_str(), homonym, mode, spelling,
                                  &text);
            else if (row[1] == "prefix")
                status = frc_common_prefix(engine, verb.c_str(), homonym, mode, &text);
            else if (row[1] == "pronoun")
                status =
                    frc_pronoun(engine, verb.c_str(), selector.c_str(), homonym, spelling, &text);
            else if (row[1] == "with_pronoun")
                status = frc_with_pronoun(engine, verb.c_str(), selector.c_str(), homonym, spelling,
                                          &text);
            else if (row[1] == "gerondif") {
                auto at = selector.find('|');
                if (at == std::string::npos)
                    throw std::runtime_error("Invalid gerondif selector");
                status = frc_gerondif(engine, verb.c_str(), selector.substr(0, at).c_str(),
                                      selector.substr(at + 1).c_str(), homonym, mode, &text);
            } else
                throw std::runtime_error("Unknown operation");
            std::unique_ptr<char, decltype(&frc_string_free)> owner(text, frc_string_free);
            if (status != (expected ? FRC_OK : FRC_MISSING) ||
                (expected && (!text || *expected != text)) || (!expected && text))
                throw std::runtime_error("Conformance case " + row[0] +
                                         " failed; actual=" + (text ? text : "<null>"));
        }
        if (!input.eof() || ids.empty())
            throw std::runtime_error("Missing or unreadable cases");
        std::cout << ids.size() << " shared conformance cases passed\n";
    } catch (const std::exception &error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
