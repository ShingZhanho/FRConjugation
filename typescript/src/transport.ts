interface Reply {
    id: number;
    value?: unknown;
    error?: string;
}
type WorkerHandle = {
    postMessage(value: unknown): void;
    terminate(): unknown;
    ref?(): void;
    unref?(): void;
};
export class Transport {
    private sequence = 0;
    private closed = false;
    private readonly pending = new Map<
        number,
        { resolve(value: unknown): void; reject(error: Error): void }
    >();
    private constructor(private readonly worker: WorkerHandle) {}
    static async create(): Promise<Transport> {
        let transport: Transport;
        const url = new URL("./worker.js", import.meta.url);
        if (typeof process !== "undefined" && process.versions?.node) {
            const moduleName = "node:worker_threads";
            const { Worker } = (await import(moduleName)) as typeof import("node:worker_threads");
            const worker = new Worker(url);
            transport = new Transport(worker);
            worker.on("message", (reply: Reply) => transport.receive(reply));
            worker.on("error", (error) => transport.fail(error));
            worker.on("exit", (code) =>
                transport.fail(new Error(`Conjugation worker exited (${code})`)),
            );
        } else {
            const worker = new Worker(new URL("./worker.js", import.meta.url), { type: "module" });
            transport = new Transport(worker);
            worker.onmessage = (event) => transport.receive(event.data as Reply);
            worker.onerror = (event) =>
                transport.fail(new Error(event.message || "Conjugation worker failed"));
            worker.onmessageerror = () => transport.fail(new Error("Invalid worker message"));
        }
        try {
            await transport.call("$ready", []);
        } catch (error) {
            transport.close();
            throw error;
        }
        return transport;
    }
    call(method: string, args: unknown[]): Promise<unknown> {
        if (this.closed) return Promise.reject(new Error("Conjugator is closed"));
        const id = ++this.sequence;
        this.worker.ref?.();
        return new Promise((resolve, reject) => {
            this.pending.set(id, { resolve, reject });
            try {
                this.worker.postMessage({ id, method, args });
            } catch (cause) {
                this.pending.delete(id);
                reject(cause);
                if (!this.pending.size) this.worker.unref?.();
            }
        });
    }
    private receive(reply: Reply): void {
        const request = this.pending.get(reply.id);
        if (!request) return;
        this.pending.delete(reply.id);
        if (reply.error !== undefined) request.reject(new Error(reply.error));
        else request.resolve(reply.value);
        if (!this.pending.size) this.worker.unref?.();
    }
    private fail(error: Error): void {
        if (this.closed) return;
        this.closed = true;
        for (const request of this.pending.values()) request.reject(error);
        this.pending.clear();
        void this.worker.terminate();
    }
    close(): void {
        this.fail(new Error("Conjugator is closed"));
    }
}
