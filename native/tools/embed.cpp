// Build-host utility: embed the shared binary without another language runtime.
#include <cstdio>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>

int main(int argc, char **argv) {
    if (argc != 3) {
        std::cerr << "usage: embed INPUT OUTPUT\n";
        return 1;
    }
    const std::string temporary = std::string(argv[2]) + ".tmp";
    try {
        std::ifstream input(argv[1], std::ios::binary);
        if (!input)
            throw std::runtime_error("Cannot open catalogue");
        std::ofstream output(temporary, std::ios::binary);
        output.exceptions(std::ios::failbit | std::ios::badbit);
        output << "static const unsigned char catalogue_bytes[] = {\n";
        unsigned count = 0;
        char byte;
        while (input.get(byte)) {
            if (count % 32 != 0)
                output << ',';
            output << static_cast<unsigned>(static_cast<unsigned char>(byte));
            if (++count % 32 == 0)
                output << ",\n";
        }
        if (!input.eof())
            throw std::runtime_error("Cannot read catalogue");
        if (count % 32 != 0)
            output << ",\n";
        output << "};\n";
        output.close();
        if (std::rename(temporary.c_str(), argv[2]) != 0)
            throw std::runtime_error("Cannot install embedded catalogue");
    } catch (const std::exception &error) {
        std::remove(temporary.c_str());
        std::cerr << error.what() << '\n';
        return 1;
    }
}
