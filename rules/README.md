# Building the conjugation rules

The Swift library reads the bundled `catalogue.fcr`. Its source is [catalogue.rules](catalogue.rules), a UTF-8 file with one JSON record per line. The learner and compiler use Python 3 and its standard library. [Text records and binary layout](FORMAT.md)

To recompile the checked-in rules, run this from the repository root.

```sh
python3 rules/compile.py rules/catalogue.rules catalogue/catalogue.fcr
```

To learn the rules again, download `verbs.db` from the [v0.5.0 dataset release](https://github.com/ShingZhanho/verbe-conjugaison-academie-francaise/releases/tag/v0.5.0). Its SHA-256 is `43ec6028c12e82b7db71823493da8baff09273f07505b4eaaf5577828599306b`. Set `db` to its local path and run the following commands from the repository root.

```sh
db=/path/to/verbs.db
mkdir -p .build/rules
python3 rules/learn.py "$db" .build/rules/catalogue.rules
python3 rules/compile.py .build/rules/catalogue.rules .build/rules/catalogue.fcr
cmp .build/rules/catalogue.rules rules/catalogue.rules
cmp .build/rules/catalogue.fcr catalogue/catalogue.fcr
```

To verify every lexical entry, spelling alternative and missing slot against the database on macOS, run the verifier.

```sh
python3 rules/oracle.py "$db" .build/rules/oracle.json
swiftc -O swift/Sources/FRConjugation/RuleFile.swift rules/Verify.swift -o .build/rules/verify-catalogue
.build/rules/verify-catalogue .build/rules/catalogue.fcr .build/rules/oracle.json
```

The **Build Conjugation Rules** workflow performs the same verification against the latest dataset release and uploads both generated files.
