#include "frconjugation_api.h"
extern "C" const char *frc_voice_label(frc_voice value) {
    static const char *labels[] = {"voix_active_avoir", "voix_active_etre", "voix_active",
                                   "voix_passive", "voix_prono"};
    int index = static_cast<int>(value);
    return index >= 0 && index < 5 ? labels[index] : nullptr;
}
extern "C" const char *frc_mood_label(frc_mood value) {
    static const char *labels[] = {"indicatif", "subjonctif", "conditionnel", "imperatif",
                                   "participe"};
    int index = static_cast<int>(value);
    return index >= 0 && index < 5 ? labels[index] : nullptr;
}
extern "C" const char *frc_tense_label(frc_tense value) {
    static const char *labels[] = {"present",           "imparfait",         "passe_simple",
                                   "futur_simple",      "passe_compose",     "plus_que_parfait",
                                   "passe_anterieur",   "futur_anterieur",   "passe",
                                   "passe_sm",          "passe_sf",          "passe_pm",
                                   "passe_pf",          "passe_compound_sm", "passe_compound_sf",
                                   "passe_compound_pm", "passe_compound_pf", "present_sm",
                                   "present_sf",        "present_pm",        "present_pf",
                                   "gerondif_present",  "gerondif_passe_sm", "gerondif_passe_sf",
                                   "gerondif_passe_pm", "gerondif_passe_pf"};
    int index = static_cast<int>(value);
    return index >= 0 && index < 26 ? labels[index] : nullptr;
}
extern "C" const char *frc_person_label(frc_person value) {
    static const char *labels[] = {"1sm", "1sf", "2sm", "2sf", "3sm", "3sf", "3sn",
                                   "1pm", "1pf", "2pm", "2pf", "3pm", "3pf"};
    int index = static_cast<int>(value);
    return index >= 0 && index < 13 ? labels[index] : nullptr;
}
extern "C" const char *frc_person_pronoun(frc_person value) {
    static const char *labels[] = {"je",   "je",   "tu",   "tu",   "il",  "elle", "on",
                                   "nous", "nous", "vous", "vous", "ils", "elles"};
    int index = static_cast<int>(value);
    return index >= 0 && index < 13 ? labels[index] : nullptr;
}

#include <cstring>
extern "C" int frc_voice_from_label(const char *label, frc_voice *out) {
    if (!label || !out)
        return 0;
    for (int i = 0; frc_voice_label(static_cast<frc_voice>(i)); ++i)
        if (std::strcmp(label, frc_voice_label(static_cast<frc_voice>(i))) == 0) {
            *out = static_cast<frc_voice>(i);
            return 1;
        }
    return 0;
}
extern "C" int frc_mood_from_label(const char *label, frc_mood *out) {
    if (!label || !out)
        return 0;
    for (int i = 0; frc_mood_label(static_cast<frc_mood>(i)); ++i)
        if (std::strcmp(label, frc_mood_label(static_cast<frc_mood>(i))) == 0) {
            *out = static_cast<frc_mood>(i);
            return 1;
        }
    return 0;
}
extern "C" int frc_tense_from_label(const char *label, frc_tense *out) {
    if (!label || !out)
        return 0;
    for (int i = 0; frc_tense_label(static_cast<frc_tense>(i)); ++i)
        if (std::strcmp(label, frc_tense_label(static_cast<frc_tense>(i))) == 0) {
            *out = static_cast<frc_tense>(i);
            return 1;
        }
    return 0;
}
extern "C" int frc_person_from_label(const char *label, frc_person *out) {
    if (!label || !out)
        return 0;
    for (int i = 0; frc_person_label(static_cast<frc_person>(i)); ++i)
        if (std::strcmp(label, frc_person_label(static_cast<frc_person>(i))) == 0) {
            *out = static_cast<frc_person>(i);
            return 1;
        }
    return 0;
}

extern "C" const char *frc_status_description(frc_status status) {
    switch (status) {
    case FRC_OK:
        return "Success";
    case FRC_MISSING:
        return "No form available";
    case FRC_INVALID_ARGUMENT:
        return "Invalid argument";
    case FRC_ERROR:
        return "Catalogue loading or operation failed";
    default:
        return "Unknown status";
    }
}
