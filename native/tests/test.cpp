#include "frconjugation.hpp"
#include <cassert>
#include <future>
#include <iostream>

int main() {
    frconjugation::Conjugator c;
    const std::string slot = "voix_active_avoir|indicatif|present|1pm";
    assert(c.slots().size() == 820);
    std::vector<std::future<void>> work;
    for (int i = 0; i < 8; ++i)
        work.push_back(std::async(std::launch::async, [&] {
            for (int j = 0; j < 100; ++j)
                assert(c.form("manger", slot) == "mangeons");
            assert(c.common_prefix("venir") == "v");
        }));
    for (auto &task : work)
        task.get();
    auto moved = std::move(c);
    assert(moved.form("manger", slot) == "mangeons");
    std::cout << "Native API checks passed\n";
}
