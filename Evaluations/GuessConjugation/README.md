# Raw and catalogue-first inference evaluation — 2026-10-30

The bundled v4.3.0 neural weights were used unchanged. Raw inference bypasses the correction table; each guess family prefers its matching catalogue API (conjugate or participle) and falls back only for missing forms. References were fixed before observing predictions; unknown verbs were checked against the model's known-verbs set. The exact reference forms, publisher URLs and sampling method are in [cases.json](cases.json). Raw predictions for every scored case and every coverage slot, with artifact/source checksums, are in [results.json](results.json).

| Sample | Cases | Raw exact full-string matches | Raw primary accepted | Hybrid primary accepted |
|---|---:|---:|---:|---:|
| unseen_dictionary | 96 | 96 | 96 | 96 |
| seen_control | 64 | 64 | 64 | 64 |
| seen_exception | 10 | 0 | 2 | 10 |

All 820 model-supported base form combinations returned nonempty raw predictions across the finite and participle families for the invented string `blorper`. This establishes API reachability, not grammatical accuracy.

Exact means the full prediction equals the reference, including alternative order. Primary accepted means the first predicted alternative is among the reference's accepted alternatives. Neither metric assesses confidence or whether additional predicted alternatives are correct.

## Unseen dictionary verbs

| Input | Exact matches | Publisher reference |
|---|---:|---|
| covoiturer | 12/12 | [Reference](https://www.larousse.fr/fr/conjugaison/francais/covoiturer/11683) |
| divulgâcher | 12/12 | [Reference](https://dictionnaire.lerobert.com/conjugaison/spoiler) |
| liker | 12/12 | [Reference](https://dictionnaire.lerobert.com/definition/liker) |
| podcaster | 12/12 | [Reference](https://dictionnaire.lerobert.com/conjugaison/podcaster) |
| streamer | 12/12 | [Reference](https://dictionnaire.lerobert.com/definition/streamer) |
| survendre | 12/12 | [Reference](https://www.larousse.fr/fr/conjugaison/francais/survendre/8808) |
| télétravailler | 12/12 | [Reference](https://www.larousse.fr/conjugaison/francais/t%C3%A9l%C3%A9travailler/11752) |
| ubériser | 12/12 | [Reference](https://www.larousse.fr/fr/conjugaison/francais/ub%C3%A9riser/11568) |

## Limits

- This is a small, curated sample: seven first-group verbs and one third-group `-re` verb (`survendre`). It does not establish accuracy for all unknown verbs, irregular patterns, misspellings, or arbitrary text.
- These eight inputs are absent from the supplied model catalogue; no retraining or verb-level held-out split was performed. The seen controls are not evidence of unseen-verb generalization.
- The ten correction-table cases deliberately target known neural errors. Their failures demonstrate why raw inference does not share the corrected catalogue API's accuracy guarantee; they are not a random sample of all known forms.
- The matching guess families retain all ten catalogue answers in the correction stress set, including both participle corrections. Participle cases are evaluated through rawInferredParticiple / guessParticiple, without person placeholders. Gérondif derivation and catalogue fallback are covered by separate API regression checks.
- The API does not infer which voices or slots are grammatically valid for a novel input. It validates only global model support. Output is bounded by the existing decoder's 50 steps and may be malformed or truncated.

## Reproduce

From the repository root:

```bash
FRCONJ_GUESS_REPORT="$PWD/Evaluations/GuessConjugation/results.json" \
  swift test -c release --filter GuessConjugationTests
python3 Evaluations/GuessConjugation/summarize.py
```

The measurement test is skipped unless the report environment variable is set. API regression tests still run normally.

## Every scored prediction

| Category | Input | Voice/mode/tense/person | Expected | Raw prediction | Raw exact | Hybrid prediction | Hybrid source |
|---|---|---|---|---|---|---|---|
| unseen_dictionary | télétravailler | voix_active_avoir/indicatif/present/1sm | télétravaille | télétravaille | yes | télétravaille | raw_fallback |
| unseen_dictionary | télétravailler | voix_active_avoir/indicatif/present/1pm | télétravaillons | télétravaillons | yes | télétravaillons | raw_fallback |
| unseen_dictionary | télétravailler | voix_active_avoir/indicatif/present/3pm | télétravaillent | télétravaillent | yes | télétravaillent | raw_fallback |
| unseen_dictionary | télétravailler | voix_active_avoir/indicatif/imparfait/1pm | télétravaillions | télétravaillions | yes | télétravaillions | raw_fallback |
| unseen_dictionary | télétravailler | voix_active_avoir/indicatif/passe_simple/1pm | télétravaillâmes | télétravaillâmes | yes | télétravaillâmes | raw_fallback |
| unseen_dictionary | télétravailler | voix_active_avoir/indicatif/futur_simple/3sm | télétravaillera | télétravaillera | yes | télétravaillera | raw_fallback |
| unseen_dictionary | télétravailler | voix_active_avoir/conditionnel/present/1sm | télétravaillerais | télétravaillerais | yes | télétravaillerais | raw_fallback |
| unseen_dictionary | télétravailler | voix_active_avoir/subjonctif/present/1pm | télétravaillions | télétravaillions | yes | télétravaillions | raw_fallback |
| unseen_dictionary | télétravailler | voix_active_avoir/imperatif/present/2sm | télétravaille | télétravaille | yes | télétravaille | raw_fallback |
| unseen_dictionary | télétravailler | voix_active_avoir/indicatif/passe_compose/1sm | ai télétravaillé | ai télétravaillé | yes | ai télétravaillé | raw_fallback |
| unseen_dictionary | télétravailler | voix_active_avoir/participe/present/- | télétravaillant | télétravaillant | yes | télétravaillant | raw_fallback |
| unseen_dictionary | télétravailler | voix_active_avoir/participe/passe_sm/- | télétravaillé | télétravaillé | yes | télétravaillé | raw_fallback |
| unseen_dictionary | podcaster | voix_active_avoir/indicatif/present/1sm | podcaste | podcaste | yes | podcaste | raw_fallback |
| unseen_dictionary | podcaster | voix_active_avoir/indicatif/present/1pm | podcastons | podcastons | yes | podcastons | raw_fallback |
| unseen_dictionary | podcaster | voix_active_avoir/indicatif/present/3pm | podcastent | podcastent | yes | podcastent | raw_fallback |
| unseen_dictionary | podcaster | voix_active_avoir/indicatif/imparfait/1pm | podcastions | podcastions | yes | podcastions | raw_fallback |
| unseen_dictionary | podcaster | voix_active_avoir/indicatif/passe_simple/1pm | podcastâmes | podcastâmes | yes | podcastâmes | raw_fallback |
| unseen_dictionary | podcaster | voix_active_avoir/indicatif/futur_simple/3sm | podcastera | podcastera | yes | podcastera | raw_fallback |
| unseen_dictionary | podcaster | voix_active_avoir/conditionnel/present/1sm | podcasterais | podcasterais | yes | podcasterais | raw_fallback |
| unseen_dictionary | podcaster | voix_active_avoir/subjonctif/present/1pm | podcastions | podcastions | yes | podcastions | raw_fallback |
| unseen_dictionary | podcaster | voix_active_avoir/imperatif/present/2sm | podcaste | podcaste | yes | podcaste | raw_fallback |
| unseen_dictionary | podcaster | voix_active_avoir/indicatif/passe_compose/1sm | ai podcasté | ai podcasté | yes | ai podcasté | raw_fallback |
| unseen_dictionary | podcaster | voix_active_avoir/participe/present/- | podcastant | podcastant | yes | podcastant | raw_fallback |
| unseen_dictionary | podcaster | voix_active_avoir/participe/passe_sm/- | podcasté | podcasté | yes | podcasté | raw_fallback |
| unseen_dictionary | covoiturer | voix_active_avoir/indicatif/present/1sm | covoiture | covoiture | yes | covoiture | raw_fallback |
| unseen_dictionary | covoiturer | voix_active_avoir/indicatif/present/1pm | covoiturons | covoiturons | yes | covoiturons | raw_fallback |
| unseen_dictionary | covoiturer | voix_active_avoir/indicatif/present/3pm | covoiturent | covoiturent | yes | covoiturent | raw_fallback |
| unseen_dictionary | covoiturer | voix_active_avoir/indicatif/imparfait/1pm | covoiturions | covoiturions | yes | covoiturions | raw_fallback |
| unseen_dictionary | covoiturer | voix_active_avoir/indicatif/passe_simple/1pm | covoiturâmes | covoiturâmes | yes | covoiturâmes | raw_fallback |
| unseen_dictionary | covoiturer | voix_active_avoir/indicatif/futur_simple/3sm | covoiturera | covoiturera | yes | covoiturera | raw_fallback |
| unseen_dictionary | covoiturer | voix_active_avoir/conditionnel/present/1sm | covoiturerais | covoiturerais | yes | covoiturerais | raw_fallback |
| unseen_dictionary | covoiturer | voix_active_avoir/subjonctif/present/1pm | covoiturions | covoiturions | yes | covoiturions | raw_fallback |
| unseen_dictionary | covoiturer | voix_active_avoir/imperatif/present/2sm | covoiture | covoiture | yes | covoiture | raw_fallback |
| unseen_dictionary | covoiturer | voix_active_avoir/indicatif/passe_compose/1sm | ai covoituré | ai covoituré | yes | ai covoituré | raw_fallback |
| unseen_dictionary | covoiturer | voix_active_avoir/participe/present/- | covoiturant | covoiturant | yes | covoiturant | raw_fallback |
| unseen_dictionary | covoiturer | voix_active_avoir/participe/passe_sm/- | covoituré | covoituré | yes | covoituré | raw_fallback |
| unseen_dictionary | ubériser | voix_active_avoir/indicatif/present/1sm | ubérise | ubérise | yes | ubérise | raw_fallback |
| unseen_dictionary | ubériser | voix_active_avoir/indicatif/present/1pm | ubérisons | ubérisons | yes | ubérisons | raw_fallback |
| unseen_dictionary | ubériser | voix_active_avoir/indicatif/present/3pm | ubérisent | ubérisent | yes | ubérisent | raw_fallback |
| unseen_dictionary | ubériser | voix_active_avoir/indicatif/imparfait/1pm | ubérisions | ubérisions | yes | ubérisions | raw_fallback |
| unseen_dictionary | ubériser | voix_active_avoir/indicatif/passe_simple/1pm | ubérisâmes | ubérisâmes | yes | ubérisâmes | raw_fallback |
| unseen_dictionary | ubériser | voix_active_avoir/indicatif/futur_simple/3sm | ubérisera | ubérisera | yes | ubérisera | raw_fallback |
| unseen_dictionary | ubériser | voix_active_avoir/conditionnel/present/1sm | ubériserais | ubériserais | yes | ubériserais | raw_fallback |
| unseen_dictionary | ubériser | voix_active_avoir/subjonctif/present/1pm | ubérisions | ubérisions | yes | ubérisions | raw_fallback |
| unseen_dictionary | ubériser | voix_active_avoir/imperatif/present/2sm | ubérise | ubérise | yes | ubérise | raw_fallback |
| unseen_dictionary | ubériser | voix_active_avoir/indicatif/passe_compose/1sm | ai ubérisé | ai ubérisé | yes | ai ubérisé | raw_fallback |
| unseen_dictionary | ubériser | voix_active_avoir/participe/present/- | ubérisant | ubérisant | yes | ubérisant | raw_fallback |
| unseen_dictionary | ubériser | voix_active_avoir/participe/passe_sm/- | ubérisé | ubérisé | yes | ubérisé | raw_fallback |
| unseen_dictionary | divulgâcher | voix_active_avoir/indicatif/present/1sm | divulgâche | divulgâche | yes | divulgâche | raw_fallback |
| unseen_dictionary | divulgâcher | voix_active_avoir/indicatif/present/1pm | divulgâchons | divulgâchons | yes | divulgâchons | raw_fallback |
| unseen_dictionary | divulgâcher | voix_active_avoir/indicatif/present/3pm | divulgâchent | divulgâchent | yes | divulgâchent | raw_fallback |
| unseen_dictionary | divulgâcher | voix_active_avoir/indicatif/imparfait/1pm | divulgâchions | divulgâchions | yes | divulgâchions | raw_fallback |
| unseen_dictionary | divulgâcher | voix_active_avoir/indicatif/passe_simple/1pm | divulgâchâmes | divulgâchâmes | yes | divulgâchâmes | raw_fallback |
| unseen_dictionary | divulgâcher | voix_active_avoir/indicatif/futur_simple/3sm | divulgâchera | divulgâchera | yes | divulgâchera | raw_fallback |
| unseen_dictionary | divulgâcher | voix_active_avoir/conditionnel/present/1sm | divulgâcherais | divulgâcherais | yes | divulgâcherais | raw_fallback |
| unseen_dictionary | divulgâcher | voix_active_avoir/subjonctif/present/1pm | divulgâchions | divulgâchions | yes | divulgâchions | raw_fallback |
| unseen_dictionary | divulgâcher | voix_active_avoir/imperatif/present/2sm | divulgâche | divulgâche | yes | divulgâche | raw_fallback |
| unseen_dictionary | divulgâcher | voix_active_avoir/indicatif/passe_compose/1sm | ai divulgâché | ai divulgâché | yes | ai divulgâché | raw_fallback |
| unseen_dictionary | divulgâcher | voix_active_avoir/participe/present/- | divulgâchant | divulgâchant | yes | divulgâchant | raw_fallback |
| unseen_dictionary | divulgâcher | voix_active_avoir/participe/passe_sm/- | divulgâché | divulgâché | yes | divulgâché | raw_fallback |
| unseen_dictionary | streamer | voix_active_avoir/indicatif/present/1sm | streame | streame | yes | streame | raw_fallback |
| unseen_dictionary | streamer | voix_active_avoir/indicatif/present/1pm | streamons | streamons | yes | streamons | raw_fallback |
| unseen_dictionary | streamer | voix_active_avoir/indicatif/present/3pm | streament | streament | yes | streament | raw_fallback |
| unseen_dictionary | streamer | voix_active_avoir/indicatif/imparfait/1pm | streamions | streamions | yes | streamions | raw_fallback |
| unseen_dictionary | streamer | voix_active_avoir/indicatif/passe_simple/1pm | streamâmes | streamâmes | yes | streamâmes | raw_fallback |
| unseen_dictionary | streamer | voix_active_avoir/indicatif/futur_simple/3sm | streamera | streamera | yes | streamera | raw_fallback |
| unseen_dictionary | streamer | voix_active_avoir/indicatif/imparfait/3pm | streamaient | streamaient | yes | streamaient | raw_fallback |
| unseen_dictionary | streamer | voix_active_avoir/indicatif/passe_simple/3sm | streama | streama | yes | streama | raw_fallback |
| unseen_dictionary | streamer | voix_active_avoir/indicatif/futur_simple/1sm | streamerai | streamerai | yes | streamerai | raw_fallback |
| unseen_dictionary | streamer | voix_active_avoir/indicatif/imparfait/1sm | streamais | streamais | yes | streamais | raw_fallback |
| unseen_dictionary | streamer | voix_active_avoir/indicatif/passe_simple/2pm | streamâtes | streamâtes | yes | streamâtes | raw_fallback |
| unseen_dictionary | streamer | voix_active_avoir/indicatif/futur_simple/1pm | streamerons | streamerons | yes | streamerons | raw_fallback |
| unseen_dictionary | liker | voix_active_avoir/indicatif/present/1sm | like | like | yes | like | raw_fallback |
| unseen_dictionary | liker | voix_active_avoir/indicatif/present/1pm | likons | likons | yes | likons | raw_fallback |
| unseen_dictionary | liker | voix_active_avoir/indicatif/present/3pm | likent | likent | yes | likent | raw_fallback |
| unseen_dictionary | liker | voix_active_avoir/indicatif/imparfait/1pm | likions | likions | yes | likions | raw_fallback |
| unseen_dictionary | liker | voix_active_avoir/indicatif/passe_simple/1pm | likâmes | likâmes | yes | likâmes | raw_fallback |
| unseen_dictionary | liker | voix_active_avoir/indicatif/futur_simple/3sm | likera | likera | yes | likera | raw_fallback |
| unseen_dictionary | liker | voix_active_avoir/indicatif/imparfait/3pm | likaient | likaient | yes | likaient | raw_fallback |
| unseen_dictionary | liker | voix_active_avoir/indicatif/passe_simple/3sm | lika | lika | yes | lika | raw_fallback |
| unseen_dictionary | liker | voix_active_avoir/indicatif/futur_simple/1sm | likerai | likerai | yes | likerai | raw_fallback |
| unseen_dictionary | liker | voix_active_avoir/indicatif/imparfait/1sm | likais | likais | yes | likais | raw_fallback |
| unseen_dictionary | liker | voix_active_avoir/indicatif/passe_simple/2pm | likâtes | likâtes | yes | likâtes | raw_fallback |
| unseen_dictionary | liker | voix_active_avoir/indicatif/futur_simple/1pm | likerons | likerons | yes | likerons | raw_fallback |
| unseen_dictionary | survendre | voix_active_avoir/indicatif/present/1sm | survends | survends | yes | survends | raw_fallback |
| unseen_dictionary | survendre | voix_active_avoir/indicatif/present/1pm | survendons | survendons | yes | survendons | raw_fallback |
| unseen_dictionary | survendre | voix_active_avoir/indicatif/present/3pm | survendent | survendent | yes | survendent | raw_fallback |
| unseen_dictionary | survendre | voix_active_avoir/indicatif/imparfait/1pm | survendions | survendions | yes | survendions | raw_fallback |
| unseen_dictionary | survendre | voix_active_avoir/indicatif/passe_simple/1pm | survendîmes | survendîmes | yes | survendîmes | raw_fallback |
| unseen_dictionary | survendre | voix_active_avoir/indicatif/futur_simple/3sm | survendra | survendra | yes | survendra | raw_fallback |
| unseen_dictionary | survendre | voix_active_avoir/conditionnel/present/1sm | survendrais | survendrais | yes | survendrais | raw_fallback |
| unseen_dictionary | survendre | voix_active_avoir/subjonctif/present/1pm | survendions | survendions | yes | survendions | raw_fallback |
| unseen_dictionary | survendre | voix_active_avoir/imperatif/present/2sm | survends | survends | yes | survends | raw_fallback |
| unseen_dictionary | survendre | voix_active_avoir/indicatif/passe_compose/1sm | ai survendu | ai survendu | yes | ai survendu | raw_fallback |
| unseen_dictionary | survendre | voix_active_avoir/participe/present/- | survendant | survendant | yes | survendant | raw_fallback |
| unseen_dictionary | survendre | voix_active_avoir/participe/passe_sm/- | survendu | survendu | yes | survendu | raw_fallback |
| seen_control | pleurnicher | voix_active_avoir/subjonctif/imparfait/3pm | pleurnichassent | pleurnichassent | yes | pleurnichassent | catalogue |
| seen_control | béer | voix_active_avoir/subjonctif/imparfait/1pm | béassions | béassions | yes | béassions | catalogue |
| seen_control | ahaner | voix_active_avoir/indicatif/passe_anterieur/3sm | eut ahané | eut ahané | yes | eut ahané | catalogue |
| seen_control | repasser | voix_active_avoir/subjonctif/plus_que_parfait/3pm | eussent repassé | eussent repassé | yes | eussent repassé | catalogue |
| seen_control | déféquer | voix_active_avoir/indicatif/futur_simple/1sm | déféquerai;défèquerai | déféquerai;défèquerai | yes | déféquerai | catalogue |
| seen_control | débuter | voix_active_avoir/conditionnel/present/1sm | débuterais | débuterais | yes | débuterais | catalogue |
| seen_control | disculper | voix_active_avoir/subjonctif/present/3pm | disculpent | disculpent | yes | disculpent | catalogue |
| seen_control | chauler | voix_active_avoir/subjonctif/present/2pm | chauliez | chauliez | yes | chauliez | catalogue |
| seen_control | disconvenir | voix_active_etre/indicatif/passe_simple/2pm | disconvîntes | disconvîntes | yes | disconvîntes | catalogue |
| seen_control | descendre | voix_active_etre/indicatif/passe_compose/1sm | suis descendu | suis descendu | yes | suis descendu | catalogue |
| seen_control | retomber | voix_active_etre/indicatif/passe_anterieur/1sm | fus retombé | fus retombé | yes | fus retombé | catalogue |
| seen_control | apparaitre | voix_active_etre/subjonctif/plus_que_parfait/2pf | fussiez apparues | fussiez apparues | yes | fussiez apparues | catalogue |
| seen_control | apparaitre | voix_active_etre/indicatif/plus_que_parfait/1sm | étais apparu | étais apparu | yes | étais apparu | catalogue |
| seen_control | devenir | voix_active_etre/indicatif/passe_anterieur/1sf | fus devenue | fus devenue | yes | fus devenue | catalogue |
| seen_control | intervenir | voix_active_etre/imperatif/present/2pm | intervenez | intervenez | yes | intervenez | catalogue |
| seen_control | mourir | voix_active_etre/conditionnel/passe/3pf | seraient mortes | seraient mortes | yes | seraient mortes | catalogue |
| seen_control | seoir | voix_active/indicatif/present/3sm | sied | sied | yes | sied | catalogue |
| seen_control | sourdre | voix_active/indicatif/futur_simple/3sm | sourdra | sourdra | yes | sourdra | catalogue |
| seen_control | chaloir | voix_active/indicatif/present/3sm | chaut | chaut | yes | chaut | catalogue |
| seen_control | sourdre | voix_active/conditionnel/present/3pm | sourdraient | sourdraient | yes | sourdraient | catalogue |
| seen_control | gésir | voix_active/indicatif/present/2pm | gisez | gisez | yes | gisez | catalogue |
| seen_control | sourdre | voix_active/indicatif/passe_simple/3pm | sourdirent | sourdirent | yes | sourdirent | catalogue |
| seen_control | seoir | voix_active/subjonctif/present/3sm | siée | siée | yes | siée | catalogue |
| seen_control | seoir | voix_active/conditionnel/present/3sm | siérait | siérait | yes | siérait | catalogue |
| seen_control | décomprimer | voix_passive/indicatif/passe_compose/1pf | avons été décomprimées | avons été décomprimées | yes | avons été décomprimées | catalogue |
| seen_control | instrumenter | voix_passive/imperatif/present/2sm | sois instrumenté | sois instrumenté | yes | sois instrumenté | catalogue |
| seen_control | racler | voix_passive/subjonctif/plus_que_parfait/1sm | eusse été raclé | eusse été raclé | yes | eusse été raclé | catalogue |
| seen_control | désembourgeoiser | voix_passive/indicatif/futur_anterieur/3sf | aura été désembourgeoisée | aura été désembourgeoisée | yes | aura été désembourgeoisée | catalogue |
| seen_control | égoutter | voix_passive/indicatif/futur_simple/1pm | serons égouttés | serons égouttés | yes | serons égouttés | catalogue |
| seen_control | accompagner | voix_passive/conditionnel/passe/3sf | aurait été accompagnée | aurait été accompagnée | yes | aurait été accompagnée | catalogue |
| seen_control | tournebouler | voix_passive/indicatif/passe_compose/2sm | as été tourneboulé | as été tourneboulé | yes | as été tourneboulé | catalogue |
| seen_control | écrouter | voix_passive/indicatif/passe_compose/1pf | avons été écroutées;avons été écroûtées | avons été écroutées;avons été écroûtées | yes | avons été écroutées | catalogue |
| seen_control | démocratiser | voix_prono/subjonctif/plus_que_parfait/1sf | me fusse démocratisée | me fusse démocratisée | yes | me fusse démocratisée | catalogue |
| seen_control | remplir | voix_prono/conditionnel/passe/3pf | se seraient remplies | se seraient remplies | yes | se seraient remplies | catalogue |
| seen_control | nominaliser | voix_prono/subjonctif/passe/3sf | se soit nominalisée | se soit nominalisée | yes | se soit nominalisée | catalogue |
| seen_control | guêtrer | voix_prono/subjonctif/plus_que_parfait/1pm | nous fussions guêtrés | nous fussions guêtrés | yes | nous fussions guêtrés | catalogue |
| seen_control | délover | voix_prono/indicatif/plus_que_parfait/2sm | t'étais délové | t'étais délové | yes | t'étais délové | catalogue |
| seen_control | engraver | voix_prono/indicatif/plus_que_parfait/3pf | s'étaient engravées | s'étaient engravées | yes | s'étaient engravées | catalogue |
| seen_control | méprendre | voix_prono/indicatif/plus_que_parfait/2sm | t'étais mépris | t'étais mépris | yes | t'étais mépris | catalogue |
| seen_control | consulter | voix_prono/indicatif/imparfait/2pm | vous consultiez | vous consultiez | yes | vous consultiez | catalogue |
| seen_control | bouillonner | voix_passive/participe/passe_compound_sm/- | ayant été bouillonné | ayant été bouillonné | yes | ayant été bouillonné | catalogue |
| seen_control | estampiller | voix_passive/participe/passe_compound_sm/- | ayant été estampillé | ayant été estampillé | yes | ayant été estampillé | catalogue |
| seen_control | brandir | voix_active_avoir/participe/passe_sf/- | brandie | brandie | yes | brandie | catalogue |
| seen_control | ennoblir | voix_active_avoir/participe/passe_pf/- | ennoblies | ennoblies | yes | ennoblies | catalogue |
| seen_control | voguer | voix_active_avoir/participe/passe_compound_pm/- | ayant vogué | ayant vogué | yes | ayant vogué | catalogue |
| seen_control | encorder | voix_passive/participe/passe_compound_pm/- | ayant été encordés | ayant été encordés | yes | ayant été encordés | catalogue |
| seen_control | poétiser | voix_active_avoir/participe/passe_compound_sm/- | ayant poétisé | ayant poétisé | yes | ayant poétisé | catalogue |
| seen_control | délurer | voix_prono/participe/passe_pf/- | délurées | délurées | yes | délurées | catalogue |
| seen_control | texturer | voix_passive/participe/present_sm/- | étant texturé | étant texturé | yes | étant texturé | catalogue |
| seen_control | antidater | voix_active_avoir/participe/passe_compound_pf/- | ayant antidaté | ayant antidaté | yes | ayant antidaté | catalogue |
| seen_control | régionaliser | voix_active_avoir/participe/passe_compound_sm/- | ayant régionalisé | ayant régionalisé | yes | ayant régionalisé | catalogue |
| seen_control | hypostasier | voix_active_avoir/participe/passe_sf/- | hypostasiée | hypostasiée | yes | hypostasiée | catalogue |
| seen_control | municipaliser | voix_active_avoir/participe/passe_compound_sf/- | ayant municipalisé | ayant municipalisé | yes | ayant municipalisé | catalogue |
| seen_control | centrifuger | voix_passive/participe/passe_compound_pm/- | ayant été centrifugés | ayant été centrifugés | yes | ayant été centrifugés | catalogue |
| seen_control | essarter | voix_active_avoir/participe/passe_compound_sf/- | ayant essarté | ayant essarté | yes | ayant essarté | catalogue |
| seen_control | barrer | voix_active_avoir/participe/passe_pf/- | barrées | barrées | yes | barrées | catalogue |
| seen_control | négocier | voix_active_avoir/participe/present/- | négociant | négociant | yes | négociant | catalogue |
| seen_control | désamidonner | voix_active_avoir/participe/passe_compound_pf/- | ayant désamidonné | ayant désamidonné | yes | ayant désamidonné | catalogue |
| seen_control | trépigner | voix_active_avoir/participe/passe_compound_sf/- | ayant trépigné | ayant trépigné | yes | ayant trépigné | catalogue |
| seen_control | rabonnir | voix_active_avoir/participe/passe_pf/- | rabonnies | rabonnies | yes | rabonnies | catalogue |
| seen_control | préserver | voix_passive/participe/present_sf/- | étant préservée | étant préservée | yes | étant préservée | catalogue |
| seen_control | épucer | voix_active_avoir/participe/passe_compound_pm/- | ayant épucé | ayant épucé | yes | ayant épucé | catalogue |
| seen_control | éclabousser | voix_passive/participe/passe_compound_pf/- | ayant été éclaboussées | ayant été éclaboussées | yes | ayant été éclaboussées | catalogue |
| seen_control | enrocher | voix_passive/participe/present_sf/- | étant enrochée | étant enrochée | yes | étant enrochée | catalogue |
| seen_exception | revenir | voix_prono/indicatif/plus_que_parfait/2pm | vous en étiez revenus | vous'en étiez revenus | no | vous en étiez revenus | catalogue |
| seen_exception | enchaîner | voix_prono/indicatif/passe_anterieur/2sm | te fus enchaîné;te fus enchainé | te fus enchaîné;me fus enchainé | no | te fus enchaîné | catalogue |
| seen_exception | venir | voix_prono/indicatif/passe_compose/2pf | vous en êtes venues | vvons entes venues | no | vous en êtes venues | catalogue |
| seen_exception | aller | voix_prono/indicatif/plus_que_parfait/2sm | t'en étais allé | t''étais allé | no | t'en étais allé | catalogue |
| seen_exception | aller | voix_prono/indicatif/passe_anterieur/3sm | s'en fut allé | s'e fut allé | no | s'en fut allé | catalogue |
| seen_exception | traîner | voix_prono/indicatif/passe_anterieur/2sf | te fus traînée;te fus trainée | te fus traînée;me fus trainée | no | te fus traînée | catalogue |
| seen_exception | enquêter | voix_prono/participe/passe_pm/- | enquêtés | enquêté | no | enquêtés | catalogue |
| seen_exception | faire | voix_prono/subjonctif/present/3pm | se fassent | se font | no | se fassent | catalogue |
| seen_exception | aller | voix_prono/subjonctif/passe/1sf | m'en sois allée | m'm'en sois allée | no | m'en sois allée | catalogue |
| seen_exception | enquêter | voix_prono/participe/passe_sf/- | enquêtée | enquêté | no | enquêtée | catalogue |
