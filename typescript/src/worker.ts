import { Conjugator } from "./conjugator.js";
const allowed = new Set([
    "hasVerb",
    "homonymIndices",
    "hasHomonyms",
    "homonymCount",
    "isHAspire",
    "blocksElisionAndLiaison",
    "is1990Reform",
    "reformVariant",
    "form",
    "forms",
    "voices",
    "modes",
    "tenses",
    "persons",
    "pronoun",
    "withPronoun",
    "conjugate",
    "rawInferredConjugation",
    "guessConjugation",
    "commonPrefix",
    "participle",
    "participles",
    "gerondif",
    "rawInferredCommonPrefix",
    "rawInferredParticiple",
    "rawInferredParticiples",
    "rawInferredGerondif",
    "guessCommonPrefix",
    "guessParticiple",
    "guessParticiples",
    "guessGerondif",
    "conjugateAlternative",
    "hasAlternativeForm",
    "getPronoun",
    "conjugateWithPronoun",
    "conjugateAlternativeWithPronoun",
    "participleAlternative",
    "hasAlternativeParticiple",
    "getSlots",
    "getEntries",
    "getAllVerbs",
    "getVerbCount",
]);
const reader = new Conjugator();
function handle(request: { id: number; method: string; args: unknown[] }): unknown {
    try {
        const { method, args } = request;
        if (method === "$ready") return { id: request.id, value: true };
        if (!allowed.has(method)) throw new Error("Unknown operation");
        const properties: Record<string, keyof Conjugator> = {
            getSlots: "slots",
            getEntries: "entries",
            getAllVerbs: "allVerbs",
            getVerbCount: "verbCount",
        };
        const property = properties[method];
        const value = property
            ? reader[property]
            : (reader as unknown as Record<string, (...args: unknown[]) => unknown>)[method](
                  ...args,
              );
        return { id: request.id, value };
    } catch (error) {
        return { id: request.id, error: error instanceof Error ? error.message : String(error) };
    }
}
if (typeof process !== "undefined" && process.versions?.node) {
    const moduleName = "node:worker_threads";
    const { parentPort } = (await import(moduleName)) as typeof import("node:worker_threads");
    if (!parentPort) throw new Error("Must run in a worker");
    parentPort.on("message", (request) => parentPort.postMessage(handle(request)));
} else {
    globalThis.onmessage = (event) => globalThis.postMessage(handle(event.data));
}
