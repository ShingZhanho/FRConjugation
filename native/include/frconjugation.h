#ifndef FRCONJUGATION_H
#define FRCONJUGATION_H
#include <stddef.h>
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif

/** @file
 * Synchronous, thread-safe queries against the bundled French catalogue.
 * Inputs are NUL-terminated UTF-8. Successful string outputs belong to the
 * caller and must be released with frc_string_free(). Missing string results
 * are NULL. Query calls may overlap; destruction requires exclusive access.
 * Exceptions never cross the C ABI. No custom catalogue loading is supported.
 * Pointer arguments must be non-NULL unless explicitly documented otherwise.
 * All verb inputs are trimmed, lowercased and NFC-normalized. Inference accepts
 * space, apostrophe, hyphen, 1, 2, semicolon, underscore, a-z and âçèéêîïôûœ.
 */
/** Opaque catalogue instance owned by the caller. */
typedef struct frc_engine frc_engine;
/** Outcome of an operation; no thread-local error state is required. */
typedef enum {
    FRC_OK,               /**< Operation succeeded. */
    FRC_MISSING,          /**< No form or prefix is available. */
    FRC_INVALID_ARGUMENT, /**< A required pointer, mode, spelling or homonym is invalid. */
    FRC_ERROR /**< Loading, allocation, decoding or another internal operation failed. */
} frc_status;
/** Borrowed description of a status code; unknown values return "Unknown status". */
const char *frc_status_description(frc_status status);
/** Prediction strategy; use one of the FRC_CATALOGUE/INFERRED/GUESS constants. */
typedef int32_t frc_mode;
/** Available prediction strategies. */
enum {
    FRC_CATALOGUE, /**< Trimmed, lowercase, NFC-normalized catalogue lookup. */
    FRC_INFERRED,  /**< Trim, lowercase and infer supported strings; output may be unattested. */
    FRC_GUESS      /**< Preserve known infinitives including missing forms; infer only unknown
                      infinitives. */
};
/** Catalogue spelling selection; inferred answers always preserve all alternatives. */
typedef int32_t frc_spelling;
/** Available spelling selections. */
enum {
    FRC_PRIMARY,     /**< First semicolon-delimited spelling. */
    FRC_ALTERNATIVE, /**< Remainder after the first semicolon, or primary if none. */
    FRC_ALL          /**< Unmodified semicolon-delimited spellings. */
};

/** Load the bundled catalogue. @param out Receives an owned engine; NULL on failure.
 * @return FRC_OK, FRC_INVALID_ARGUMENT for NULL out, or FRC_ERROR on load failure. */
frc_status frc_create(frc_engine **out);
/** Release an engine after all queries finish. NULL is allowed. */
void frc_destroy(frc_engine *engine);
/** Release an owned string returned by this API. NULL is allowed. */
void frc_string_free(char *value);
/** Return the number of discoverable slots, or zero for a NULL engine. */
size_t frc_slot_count(const frc_engine *engine);
/** Return the number of entries including homonyms, or zero for a NULL engine. */
size_t frc_entry_count(const frc_engine *engine);
/** Copy the slot label at a zero-based index. Out-of-range indices return FRC_INVALID_ARGUMENT.
 * @param out Receives a caller-owned UTF-8 string; release with frc_string_free(). */
frc_status frc_slot_name(const frc_engine *engine, size_t index, char **out);
/** Copy an entry at a zero-based index; out-of-range returns FRC_INVALID_ARGUMENT.
 * @param key Receives the owned infinitive key, including any homonym suffix.
 * @param flags Receives bits 0: h aspiré, 1: elision/liaison blocking, 2: 1990 reform.
 * @param variant Receives an owned reform variant or NULL. Free key and variant separately.
 * All three output pointers are required; key and variant must be distinct. */
frc_status frc_entry(const frc_engine *engine, size_t index, char **key, uint32_t *flags,
                     char **variant);
/** Return one form, or FRC_MISSING for unknown input/slot or unavailable forms.
 * @param verb Infinitive or exact homonym key.
 * @param slot Label from frc_slot_name(), formatted voice|mode|tense|person.
 * Examples: voix_active_avoir|indicatif|present|1pm and
 * voix_active_avoir|participe|passe_sm|-.
 * @param homonym Zero selects the first indexed entry; positive values select that index.
 * Exact keys take precedence. Negative values are invalid.
 * @param mode Catalogue, inference, or catalogue-first guessing.
 * @param spelling Selection for catalogue output only; inference retains all alternatives.
 * @param out Receives an owned string. Predictions are not guaranteed grammatical. */
frc_status frc_form(const frc_engine *engine, const char *verb, const char *slot, int homonym,
                    frc_mode mode, frc_spelling spelling, char **out);
/** Find shared spelling across all voices, tenses and alternatives.
 * Auxiliaries and attached pronouns are excluded; this is not a grammatical stem.
 * Uses the same verb, homonym and mode semantics as frc_form().
 * @param out Receives an owned prefix. Empty is valid; FRC_MISSING means no usable forms. */
frc_status frc_common_prefix(const frc_engine *engine, const char *verb, int homonym, frc_mode mode,
                             char **out);
/** Derive a gérondif with en. Catalogue results use the primary participle;
 * inferred results prefix each underlying alternative separately.
 * @param voice Catalogue voice label.
 * @param tense gerondif_present or gerondif_passe_sm/sf/pm/pf.
 * Other parameters follow frc_form(); unavailable forms return FRC_MISSING.
 * @param out Receives an owned UTF-8 result. */
frc_status frc_gerondif(const frc_engine *engine, const char *verb, const char *voice,
                        const char *tense, int homonym, frc_mode mode, char **out);
/** Return a catalogue subject prefix, including its trailing space or apostrophe.
 * Handles elision and subjunctive que/qu’. Imperatives, participles and missing
 * forms return FRC_MISSING. Parameters follow frc_form(); FRC_ALL is invalid.
 * @param out Receives an owned prefix suitable for direct concatenation. */
frc_status frc_pronoun(const frc_engine *engine, const char *verb, const char *slot, int homonym,
                       frc_spelling spelling, char **out);
/** Return the catalogue form prefixed with its subject where applicable.
 * Imperatives and participles are returned bare. Parameters follow frc_form();
 * FRC_ALL is invalid. Missing forms return FRC_MISSING.
 * @param out Receives an owned UTF-8 result. */
frc_status frc_with_pronoun(const frc_engine *engine, const char *verb, const char *slot,
                            int homonym, frc_spelling spelling, char **out);
#ifdef __cplusplus
}
#endif
#endif
