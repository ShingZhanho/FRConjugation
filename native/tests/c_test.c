#include "frconjugation.h"
#include "frconjugation_api.h"
#include <assert.h>
#include <string.h>

int main(void) {
    frc_voice voice;
    assert(frc_voice_from_label("voix_active_avoir", &voice));
    assert(voice == FRC_VOICE_ACTIVE_AVOIR);
    frc_request request = frc_request_init(FRC_QUERY_CONJUGATE, "manger");
    request.voice = voice;
    (void)request;
    frc_engine *engine = NULL;
    assert(frc_create(&engine) == FRC_OK);
    assert(frc_slot_count(engine) == 820);
    char *text = NULL;
    const char *slot = "voix_active_avoir|indicatif|present|1pm";
    assert(frc_form(engine, "manger", slot, 0, FRC_CATALOGUE, FRC_PRIMARY, &text) == FRC_OK);
    assert(strcmp(text, "mangeons") == 0);
    frc_string_free(text);
    assert(frc_form(engine, "unknown", slot, 0, FRC_CATALOGUE, FRC_PRIMARY, &text) == FRC_MISSING);
    assert(text == NULL);
    assert(frc_common_prefix(engine, "aller", 0, FRC_CATALOGUE, &text) == FRC_OK);
    assert(text && strcmp(text, "") == 0);
    frc_string_free(text);
    assert(frc_form(engine, "\xff", slot, 0, FRC_INFERRED, FRC_PRIMARY, &text) ==
           FRC_INVALID_ARGUMENT);
    assert(text == NULL);
    assert(frc_form(NULL, "manger", slot, 0, FRC_CATALOGUE, FRC_PRIMARY, &text) ==
           FRC_INVALID_ARGUMENT);
    assert(frc_form(engine, NULL, slot, 0, FRC_CATALOGUE, FRC_PRIMARY, &text) ==
           FRC_INVALID_ARGUMENT);
    assert(frc_form(engine, "manger", NULL, 0, FRC_CATALOGUE, FRC_PRIMARY, &text) ==
           FRC_INVALID_ARGUMENT);
    assert(frc_form(engine, "manger", slot, 0, (frc_mode)99, FRC_PRIMARY, &text) ==
           FRC_INVALID_ARGUMENT);
    assert(frc_form(engine, "manger", slot, 0, FRC_CATALOGUE, FRC_PRIMARY, NULL) ==
           FRC_INVALID_ARGUMENT);
    assert(frc_slot_name(engine, 820, &text) == FRC_INVALID_ARGUMENT);
    char *key = NULL, *variant = NULL;
    uint32_t flags;
    assert(frc_entry(engine, 0, &key, &flags, &variant) == FRC_OK);
    assert(key);
    frc_string_free(key);
    frc_string_free(variant);
    frc_destroy(engine);
    frc_destroy(NULL);
    frc_string_free(NULL);
    return 0;
}
