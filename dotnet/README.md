# C# / .NET

Package and namespace: `JacobS.FRConjugation`. Targets .NET Standard 2.1;
the test executable requires .NET 10. The rules are embedded without runtime
package dependencies. Run from the repository root:

```sh
dotnet build dotnet/JacobS.FRConjugation -c Release
dotnet run --project dotnet/Tests -c Release
dotnet pack dotnet/JacobS.FRConjugation -c Release
```

Reference the project locally or install the resulting NuGet package from a local
feed. Building a package does not publish it to nuget.org. XML API documentation
is included in the package; missing public documentation fails the build.

```csharp
using JacobS.FRConjugation;

var c = Conjugator.GetShared();
var form = c.Conjugate("manger", Voice.ActiveAvoir, Mode.Indicatif,
    Tense.Present, Person.FirstPluralMasculine); // "mangeons"
var forms = c.Conjugate("manger");
var prefix = c.CommonPrefix("manger"); // "mang"
```

`Conjugate`, `RawInferredConjugation`, and `GuessConjugation` have five scopes,
from one person to all voices. Nested dictionaries follow voice → mode → tense →
person; supplied selectors remove leading levels. Single/all-voice absence is
null; other missing collections are empty. `Participle`, `Participles`, and
`Gerondif` have raw-inference and guess counterparts. Participle collections map
tense to spelling without person keys.

Use `ConjugateAlternative`, `ParticipleAlternative`, and `HasAlternative…` for
variants; `GetPronoun`, `ConjugateWithPronoun`, and
`ConjugateAlternativeWithPronoun` for subjects. Prefix strategies are
`CommonPrefix`, `RawInferredCommonPrefix`, and `GuessCommonPrefix`.

`Voices`, `Modes`, `Tenses`, and `Persons` discover structure. `AllVerbs`,
`VerbCount`, `HasVerb`, `HasHomonyms`, `HomonymCount`, `HomonymIndices`,
`IsHAspire`, `BlocksElisionAndLiaison`, `Is1990Reform`, and `ReformVariant`
provide metadata. Optional positive `homonymIndex` selects an indexed entry.
Grammar enums have `Label()` extensions; Person has `Pronoun()` and `ShortLabel()`.
`Grammar.Parse…` and `TryParse…` convert catalogue labels.

Methods ending in `Async` return Tasks dispatched through the .NET thread pool.
`LoadAsync()` creates a reader; `GetSharedAsync()` obtains the shared reader.
Synchronous methods run on the caller; no API interrupts already running work.
Resource failures throw `ConjugationException` with the underlying cause.
