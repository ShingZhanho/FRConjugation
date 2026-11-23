// Optional integration check: npm run test:browser (requires installed Chrome).
import { chromium } from "playwright";
import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { resolve, sep } from "node:path";
const root = resolve(fileURLToPath(new URL("../../", import.meta.url)));
const server = createServer(async (request, response) => {
    try {
        const path = resolve(root, "." + new URL(request.url, "http://localhost").pathname);
        if (!path.startsWith(root + sep) && path !== root) throw new Error("Invalid path");
        if (path === root || path === root + sep) {
            response.setHeader("Content-Type", "text/html");
            response.end("<!doctype html><title>Conformance</title>");
            return;
        }
        response.setHeader(
            "Content-Type",
            /\.[cm]?js$/.test(path) ? "text/javascript" : "text/plain",
        );
        response.end(await readFile(path));
    } catch {
        response.statusCode = 404;
        response.end();
    }
});
await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
let browser;
try {
    browser = await chromium.launch({
        channel: process.env.BROWSER_CHANNEL || "chrome",
        headless: true,
    });
    const page = await browser.newPage();
    await page.goto(`http://127.0.0.1:${server.address().port}/`);
    const count = await page.evaluate(async () => {
        const { Conjugator, AsyncConjugator } = await import("/typescript/dist/index.js");
        const { shared, typed, decode } = await import("/typescript/test/evaluate.mjs");
        const worker = await AsyncConjugator.load();
        let count = 0;
        try {
            for (const c of [new Conjugator(), worker]) {
                for (const [file, evaluator, column] of [
                    ["conformance.tsv", shared, 7],
                    ["typed-api.tsv", typed, 9],
                ]) {
                    const content = await (await fetch("/tests/" + file)).text();
                    for (const line of content.trimEnd().split("\n").slice(1)) {
                        const row = line.split("\t");
                        const actual = await evaluator(c, row);
                        if (actual !== decode(row[column]))
                            throw new Error(`${file} ${row[0]}: ${actual}`);
                        count++;
                    }
                }
            }
        } finally {
            worker.close();
        }
        return count;
    });
    console.log(`${count} browser checks passed (sync and Web Worker).`);
} finally {
    await browser?.close();
    await new Promise((resolve) => server.close(resolve));
}
