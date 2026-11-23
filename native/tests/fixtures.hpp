#pragma once
#include <vector>
#include <string>
#include <optional>
#include <stdexcept>
inline std::vector<std::string> fields(const std::string &line) {
    std::vector<std::string> result;
    size_t start = 0;
    for (;;) {
        auto end = line.find('\t', start);
        result.push_back(line.substr(start, end - start));
        if (end == std::string::npos)
            return result;
        start = end + 1;
    }
}
inline std::optional<std::string> decode(const std::string &text) {
    if (text == "\\N")
        return std::nullopt;
    std::string result;
    for (size_t i = 0; i < text.size(); ++i) {
        if (text[i] != '\\') {
            result += text[i];
            continue;
        }
        if (++i == text.size())
            throw std::runtime_error("Truncated escape");
        switch (text[i]) {
        case 'n':
            result += '\n';
            break;
        case 'r':
            result += '\r';
            break;
        case 't':
            result += '\t';
            break;
        case '\\':
            result += '\\';
            break;
        default:
            throw std::runtime_error("Invalid escape");
        }
    }
    return result;
}
