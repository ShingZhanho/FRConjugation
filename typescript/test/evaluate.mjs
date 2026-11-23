import { Conjugator, Voice, Mode, Tense, Person, personPronoun } from "../dist/index.js";
export const decode = (s) =>
    s === "\\N"
        ? null
        : s.replace(/\\([\\tnr])/g, (_, x) => ({ "\\": "\\", t: "\t", n: "\n", r: "\r" })[x]);
const flatten = (value, prefix = []) => {
    if (value === null || typeof value === "string") return value;
    const lines = [];
    const walk = (node, path) => {
        for (const [key, child] of Object.entries(node)) {
            if (typeof child === "string") lines.push([...path, key].join("|") + "=" + child);
            else walk(child, [...path, key]);
        }
    };
    walk(value, prefix);
    return lines.sort().join("\n");
};
export async function typed(c, r) {
    const [, op, verb] = r;
    const selectors = r.slice(3, 7).map((s) => (s === "-" ? undefined : s));
    const [v, , t] = selectors;
    const h = Number(r[7]) || undefined;
    if (op.startsWith("enum_"))
        return Object.values(
            { enum_voice: Voice, enum_mode: Mode, enum_tense: Tense, enum_person: Person }[op],
        ).join(",");
    if (op === "person_pronouns") return Object.values(Person).map(personPronoun).join(",");
    if (op === "all_verbs")
        return (c instanceof Conjugator ? c.allVerbs : await c.getAllVerbs()).join(",");
    if (op === "verb_count")
        return String(c instanceof Conjugator ? c.verbCount : await c.getVerbCount());
    const names = {
        has_verb: "hasVerb",
        has_homonyms: "hasHomonyms",
        homonym_count: "homonymCount",
        homonym_indices: "homonymIndices",
        h_aspire: "isHAspire",
        blocking: "blocksElisionAndLiaison",
        reform: "is1990Reform",
        variant: "reformVariant",
    };
    const scalar = (value) =>
        typeof value === "boolean"
            ? value
                ? "1"
                : "0"
            : Array.isArray(value)
              ? value.join(",")
              : typeof value === "number"
                ? String(value)
                : value;
    if (op in names) return scalar(await c[names[op]](verb, ...(op === "blocking" ? [h] : [])));
    if (["voices", "modes", "tenses", "persons"].includes(op)) {
        const count = ["voices", "modes", "tenses", "persons"].indexOf(op);
        return (await c[op](verb, ...selectors.slice(0, count), h)).join(",");
    }
    const methods = {
        alternative: "conjugateAlternative",
        has_alternative: "hasAlternativeForm",
        pronoun: "getPronoun",
        with_pronoun: "conjugateWithPronoun",
        alternative_with_pronoun: "conjugateAlternativeWithPronoun",
        participle_alternative: "participleAlternative",
        has_alternative_participle: "hasAlternativeParticiple",
    };
    if (op in methods)
        return scalar(
            await c[methods[op]](verb, ...(op.includes("participle") ? [v, t] : selectors), h),
        );
    const prefix = { catalogue: "", inferred: "rawInferred", guess: "guess" }[r[8]];
    if (op === "finite") {
        const value = await c[prefix ? prefix + "Conjugation" : "conjugate"](verb, ...selectors, h);
        return flatten(
            value,
            selectors.filter((x) => x !== undefined),
        );
    }
    const name = prefix ? prefix + op[0].toUpperCase() + op.slice(1) : op;
    return flatten(await c[name](verb, ...(op === "participles" ? [v] : [v, t]), h));
}
export async function shared(c, row) {
    const [, op, mode, verb, selector, homonym, spelling] = row.map(decode);
    const h = Number(homonym) || undefined;
    if (op === "prefix")
        return c[
            {
                catalogue: "commonPrefix",
                inferred: "rawInferredCommonPrefix",
                guess: "guessCommonPrefix",
            }[mode]
        ](verb, h);
    if (op === "form") return c.form(verb, selector, mode, h, spelling);
    if (op === "pronoun") return c.pronoun(verb, selector, h, spelling);
    if (op === "with_pronoun") return c.withPronoun(verb, selector, h, spelling);
    if (op === "gerondif")
        return c[
            { catalogue: "gerondif", inferred: "rawInferredGerondif", guess: "guessGerondif" }[mode]
        ](verb, ...selector.split("|"), h);
    throw new Error(`Unknown ${op}`);
}
