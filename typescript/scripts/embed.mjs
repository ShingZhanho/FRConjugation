import { readFile, writeFile } from "node:fs/promises";
const bytes = await readFile(new URL("../../catalogue/catalogue.fcr", import.meta.url));
await writeFile(
    new URL("../src/bundled.ts", import.meta.url),
    `// Generated from the canonical catalogue; do not edit.\nexport const bundled: string = ${JSON.stringify(bytes.toString("base64"))};\n`,
);
