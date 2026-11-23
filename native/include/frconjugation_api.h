#ifndef FRCONJUGATION_API_H
#define FRCONJUGATION_API_H
#include "frconjugation.h"
#include "frconjugation_types.h"
#ifdef __cplusplus
extern "C" {
#endif
/** Typed operations. Prediction selects catalogue/raw/guess for form families. */
typedef enum {
    FRC_QUERY_CONJUGATE,    /**< Finite single/bulk forms; trailing ANY selectors widen scope. */
    FRC_QUERY_PARTICIPLE,   /**< Single gendered participle. */
    FRC_QUERY_PARTICIPLES,  /**< All available participles in a voice. */
    FRC_QUERY_GERONDIF,     /**< Single derived gerondif. */
    FRC_QUERY_PREFIX,       /**< Common spelling across every form and alternative. */
    FRC_QUERY_PRONOUN,      /**< Catalogue subject prefix. */
    FRC_QUERY_WITH_PRONOUN, /**< Catalogue finite form with contextual subject. */
    FRC_QUERY_HAS_ALTERNATIVE_FORM,       /**< Boolean alternative availability. */
    FRC_QUERY_HAS_ALTERNATIVE_PARTICIPLE, /**< Boolean participle alternative availability. */
    FRC_QUERY_VOICES,                     /**< Available voices in raw-label order. */
    FRC_QUERY_MODES,                      /**< Available moods in a voice. */
    FRC_QUERY_TENSES,                     /**< Available tenses in a voice/mood. */
    FRC_QUERY_PERSONS,         /**< Persons grouped by full spelling in declaration order. */
    FRC_QUERY_ALL_VERBS,       /**< Base infinitives in French-oriented order. */
    FRC_QUERY_VERB_COUNT,      /**< Distinct base infinitive count. */
    FRC_QUERY_HAS_VERB,        /**< Exact key or base-homonym membership. */
    FRC_QUERY_HAS_HOMONYMS,    /**< Whether a base has indexed homonyms. */
    FRC_QUERY_HOMONYM_COUNT,   /**< Index count or one, including unknown inputs. */
    FRC_QUERY_HOMONYM_INDICES, /**< Ascending indices for a base name. */
    FRC_QUERY_IS_H_ASPIRE,     /**< Exact-key lexical flag. */
    FRC_QUERY_BLOCKS_ELISION,  /**< Resolved-entry lexical blocking flag. */
    FRC_QUERY_IS_1990_REFORM,  /**< Exact-key reform flag. */
    FRC_QUERY_REFORM_VARIANT   /**< Exact-key reform variant, or missing. */
} frc_operation;
/** Request. Initialize with frc_request_init, then set applicable selectors.
 * verb is borrowed for a sync call and copied before an async call returns.
 * homonym=0 selects the first index; prediction/spelling follow frc_form.
 * CONJUGATE accepts a contiguous prefix of voice/mood/tense/person; omitted
 * trailing selectors must be ANY. Other operations require their named scope.
 */
typedef struct {
    frc_operation operation; /**< Operation to perform. */
    const char *verb;        /**< UTF-8 infinitive, required (empty allowed for listing). */
    frc_voice voice;         /**< Voice or ANY. */
    frc_mood mood;           /**< Mood or ANY. */
    frc_tense tense;         /**< Tense or ANY. */
    frc_person person;       /**< Person or ANY. */
    int homonym;             /**< Zero for default; positive explicit index. */
    frc_mode prediction;     /**< Catalogue, inferred, or guess. */
    frc_spelling spelling;   /**< Catalogue spelling selection. */
} frc_request;
/** Owned immutable query result. Free with frc_response_free. */
typedef struct frc_response frc_response;
/** A bulk form record. The borrowed text remains valid until response destruction.
 * C uses an array of typed records instead of nested dictionaries. Every record
 * contains its full coordinates, so callers need not reconstruct slot strings.
 */
typedef struct {
    frc_voice voice;   /**< Form voice. */
    frc_mood mood;     /**< Form mood. */
    frc_tense tense;   /**< Form tense. */
    frc_person person; /**< Form person, ANY for a participle. */
    const char *text;  /**< Borrowed form text. */
} frc_form_row;
/** Default request with all selectors ANY, catalogue/primary mode and default homonym. */
frc_request frc_request_init(frc_operation operation, const char *verb);
/** Execute a typed request. FRC_MISSING denotes missing single/all-voice output;
 * scoped empty bulk queries succeed with zero rows. Output is NULL on error or
 * missing result. Results own all their data independently of the engine.
 */
frc_status frc_query(const frc_engine *engine, const frc_request *request, frc_response **out);
/** Release the complete result; NULL is allowed. */
void frc_response_free(frc_response *response);
/** Borrowed single text result, or NULL if not a text operation. */
const char *frc_response_text(const frc_response *response);
/** Boolean (0/1) or count result; zero for NULL. */
size_t frc_response_number(const frc_response *response);
/** Number of bulk form records. */
size_t frc_response_row_count(const frc_response *response);
/** Borrow a bulk row; NULL for an invalid index. */
const frc_form_row *frc_response_row(const frc_response *response, size_t index);
/** Number of structure/homonym integers. */
size_t frc_response_value_count(const frc_response *response);
/** Read a typed enum value or homonym index; -1 for an invalid index. */
int frc_response_value(const frc_response *response, size_t index);
/** Number of base infinitive strings. */
size_t frc_response_string_count(const frc_response *response);
/** Borrow a base infinitive; NULL for an invalid index. */
const char *frc_response_string(const frc_response *response, size_t index);
/** Callback on a worker thread, exactly once after successful scheduling.
 * The callback owns response and must free it. context must outlive the callback.
 * Callbacks must not throw. No cancellation is provided, matching Swift's work.
 */
typedef void (*frc_query_callback)(frc_status status, frc_response *response, void *context);
/** Copy request/input and schedule a query. The caller may destroy its engine
 * immediately after return. On scheduling failure no callback is invoked.
 */
frc_status frc_query_async(const frc_engine *engine, const frc_request *request,
                           frc_query_callback callback, void *context);
/** Completion of asynchronous initialization; callback owns the engine on success. */
typedef void (*frc_engine_callback)(frc_status status, frc_engine *engine, void *context);
/** Load on a worker thread; callback ownership/scheduling rules match frc_query_async. */
frc_status frc_create_async(frc_engine_callback callback, void *context);
/** Acquire an owned handle sharing the bundled immutable catalogue. */
frc_status frc_get_shared(frc_engine **out);
/** Obtain a shared-catalogue handle off the caller thread. */
frc_status frc_get_shared_async(frc_engine_callback callback, void *context);
#ifdef __cplusplus
}
#endif
#endif
