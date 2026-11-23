namespace JacobS.FRConjugation {
    /// <summary>French grammatical voice; use Label() for catalogue spelling.</summary>
    public enum Voice {
        /// <summary>voix_active_avoir.</summary>
        ActiveAvoir,
        /// <summary>voix_active_etre.</summary>
        ActiveEtre,
        /// <summary>voix_active.</summary>
        Active,
        /// <summary>voix_passive.</summary>
        Passive,
        /// <summary>voix_prono.</summary>
        Pronominal,
    }
    /// <summary>French grammatical mode; use Label() for catalogue spelling.</summary>
    public enum Mode {
        /// <summary>indicatif.</summary>
        Indicatif,
        /// <summary>subjonctif.</summary>
        Subjonctif,
        /// <summary>conditionnel.</summary>
        Conditionnel,
        /// <summary>imperatif.</summary>
        Imperatif,
        /// <summary>participe.</summary>
        Participe,
    }
    /// <summary>French grammatical tense; use Label() for catalogue spelling.</summary>
    public enum Tense {
        /// <summary>present.</summary>
        Present,
        /// <summary>imparfait.</summary>
        Imparfait,
        /// <summary>passe_simple.</summary>
        PasseSimple,
        /// <summary>futur_simple.</summary>
        FuturSimple,
        /// <summary>passe_compose.</summary>
        PasseCompose,
        /// <summary>plus_que_parfait.</summary>
        PlusQueParfait,
        /// <summary>passe_anterieur.</summary>
        PasseAnterieur,
        /// <summary>futur_anterieur.</summary>
        FuturAnterieur,
        /// <summary>passe.</summary>
        Passe,
        /// <summary>passe_sm.</summary>
        PasseMasculinSingulier,
        /// <summary>passe_sf.</summary>
        PasseFemininSingulier,
        /// <summary>passe_pm.</summary>
        PasseMasculinPluriel,
        /// <summary>passe_pf.</summary>
        PasseFemininPluriel,
        /// <summary>passe_compound_sm.</summary>
        PasseCompoundMasculinSingulier,
        /// <summary>passe_compound_sf.</summary>
        PasseCompoundFemininSingulier,
        /// <summary>passe_compound_pm.</summary>
        PasseCompoundMasculinPluriel,
        /// <summary>passe_compound_pf.</summary>
        PasseCompoundFemininPluriel,
        /// <summary>present_sm.</summary>
        PresentMasculinSingulier,
        /// <summary>present_sf.</summary>
        PresentFemininSingulier,
        /// <summary>present_pm.</summary>
        PresentMasculinPluriel,
        /// <summary>present_pf.</summary>
        PresentFemininPluriel,
        /// <summary>gerondif_present.</summary>
        GerondifPresent,
        /// <summary>gerondif_passe_sm.</summary>
        GerondifPasseMasculinSingulier,
        /// <summary>gerondif_passe_sf.</summary>
        GerondifPasseFemininSingulier,
        /// <summary>gerondif_passe_pm.</summary>
        GerondifPasseMasculinPluriel,
        /// <summary>gerondif_passe_pf.</summary>
        GerondifPasseFemininPluriel,
    }
    /// <summary>French grammatical person; use Label() for catalogue spelling.</summary>
    public enum Person {
        /// <summary>1sm.</summary>
        FirstSingularMasculine,
        /// <summary>1sf.</summary>
        FirstSingularFeminine,
        /// <summary>2sm.</summary>
        SecondSingularMasculine,
        /// <summary>2sf.</summary>
        SecondSingularFeminine,
        /// <summary>3sm.</summary>
        ThirdSingularMasculine,
        /// <summary>3sf.</summary>
        ThirdSingularFeminine,
        /// <summary>3sn.</summary>
        ThirdSingularNeutral,
        /// <summary>1pm.</summary>
        FirstPluralMasculine,
        /// <summary>1pf.</summary>
        FirstPluralFeminine,
        /// <summary>2pm.</summary>
        SecondPluralMasculine,
        /// <summary>2pf.</summary>
        SecondPluralFeminine,
        /// <summary>3pm.</summary>
        ThirdPluralMasculine,
        /// <summary>3pf.</summary>
        ThirdPluralFeminine,
    }
    /// <summary>Catalogue labels and grammatical-person convenience properties.</summary>
    public static class Grammar {
        /// <summary>Return the catalogue label; invalid enum values throw ArgumentOutOfRangeException.</summary>
        public static string Label(this Voice value) => value switch {
            Voice.ActiveAvoir => "voix_active_avoir",
            Voice.ActiveEtre => "voix_active_etre",
            Voice.Active => "voix_active",
            Voice.Passive => "voix_passive",
            Voice.Pronominal => "voix_prono",
            _ => throw new System.ArgumentOutOfRangeException(nameof(value))
        };
        /// <summary>Return the catalogue label; invalid enum values throw ArgumentOutOfRangeException.</summary>
        public static string Label(this Mode value) => value switch {
            Mode.Indicatif => "indicatif",
            Mode.Subjonctif => "subjonctif",
            Mode.Conditionnel => "conditionnel",
            Mode.Imperatif => "imperatif",
            Mode.Participe => "participe",
            _ => throw new System.ArgumentOutOfRangeException(nameof(value))
        };
        /// <summary>Return the catalogue label; invalid enum values throw ArgumentOutOfRangeException.</summary>
        public static string Label(this Tense value) => value switch {
            Tense.Present => "present",
            Tense.Imparfait => "imparfait",
            Tense.PasseSimple => "passe_simple",
            Tense.FuturSimple => "futur_simple",
            Tense.PasseCompose => "passe_compose",
            Tense.PlusQueParfait => "plus_que_parfait",
            Tense.PasseAnterieur => "passe_anterieur",
            Tense.FuturAnterieur => "futur_anterieur",
            Tense.Passe => "passe",
            Tense.PasseMasculinSingulier => "passe_sm",
            Tense.PasseFemininSingulier => "passe_sf",
            Tense.PasseMasculinPluriel => "passe_pm",
            Tense.PasseFemininPluriel => "passe_pf",
            Tense.PasseCompoundMasculinSingulier => "passe_compound_sm",
            Tense.PasseCompoundFemininSingulier => "passe_compound_sf",
            Tense.PasseCompoundMasculinPluriel => "passe_compound_pm",
            Tense.PasseCompoundFemininPluriel => "passe_compound_pf",
            Tense.PresentMasculinSingulier => "present_sm",
            Tense.PresentFemininSingulier => "present_sf",
            Tense.PresentMasculinPluriel => "present_pm",
            Tense.PresentFemininPluriel => "present_pf",
            Tense.GerondifPresent => "gerondif_present",
            Tense.GerondifPasseMasculinSingulier => "gerondif_passe_sm",
            Tense.GerondifPasseFemininSingulier => "gerondif_passe_sf",
            Tense.GerondifPasseMasculinPluriel => "gerondif_passe_pm",
            Tense.GerondifPasseFemininPluriel => "gerondif_passe_pf",
            _ => throw new System.ArgumentOutOfRangeException(nameof(value))
        };
        /// <summary>Return the catalogue label; invalid enum values throw ArgumentOutOfRangeException.</summary>
        public static string Label(this Person value) => value switch {
            Person.FirstSingularMasculine => "1sm",
            Person.FirstSingularFeminine => "1sf",
            Person.SecondSingularMasculine => "2sm",
            Person.SecondSingularFeminine => "2sf",
            Person.ThirdSingularMasculine => "3sm",
            Person.ThirdSingularFeminine => "3sf",
            Person.ThirdSingularNeutral => "3sn",
            Person.FirstPluralMasculine => "1pm",
            Person.FirstPluralFeminine => "1pf",
            Person.SecondPluralMasculine => "2pm",
            Person.SecondPluralFeminine => "2pf",
            Person.ThirdPluralMasculine => "3pm",
            Person.ThirdPluralFeminine => "3pf",
            _ => throw new System.ArgumentOutOfRangeException(nameof(value))
        };
        /// <summary>Compact catalogue person label.</summary>
        public static string ShortLabel(this Person value) => value.Label();
        /// <summary>French subject pronoun without contextual elision.</summary>
        public static string Pronoun(this Person value) => value.Label() switch {
            "1sm" or "1sf" => "je",
            "2sm" or "2sf" => "tu",
            "3sm" => "il",
            "3sf" => "elle",
            "3sn" => "on",
            "1pm" or "1pf" => "nous",
            "2pm" or "2pf" => "vous",
            "3pm" => "ils",
            _ => "elles"
        };
        /// <summary>Parse a catalogue label; throws ArgumentException when unknown.</summary>
        public static Voice ParseVoice(string label) {
            if (TryParseVoice(label, out var value))
                return value;
            throw new System.ArgumentException("Unknown voice label", nameof(label));
        }
        /// <summary>Try to parse a catalogue label; returns false if unknown or null.</summary>
        public static bool TryParseVoice(string? label, out Voice value) {
            foreach (Voice item in System.Enum.GetValues(typeof(Voice)))
                if (item.Label() == label) {
                    value = item;
                    return true;
                }
            value = default;
            return false;
        }
        /// <summary>Parse a catalogue label; throws ArgumentException when unknown.</summary>
        public static Mode ParseMode(string label) {
            if (TryParseMode(label, out var value))
                return value;
            throw new System.ArgumentException("Unknown mode label", nameof(label));
        }
        /// <summary>Try to parse a catalogue label; returns false if unknown or null.</summary>
        public static bool TryParseMode(string? label, out Mode value) {
            foreach (Mode item in System.Enum.GetValues(typeof(Mode)))
                if (item.Label() == label) {
                    value = item;
                    return true;
                }
            value = default;
            return false;
        }
        /// <summary>Parse a catalogue label; throws ArgumentException when unknown.</summary>
        public static Tense ParseTense(string label) {
            if (TryParseTense(label, out var value))
                return value;
            throw new System.ArgumentException("Unknown tense label", nameof(label));
        }
        /// <summary>Try to parse a catalogue label; returns false if unknown or null.</summary>
        public static bool TryParseTense(string? label, out Tense value) {
            foreach (Tense item in System.Enum.GetValues(typeof(Tense)))
                if (item.Label() == label) {
                    value = item;
                    return true;
                }
            value = default;
            return false;
        }
        /// <summary>Parse a catalogue label; throws ArgumentException when unknown.</summary>
        public static Person ParsePerson(string label) {
            if (TryParsePerson(label, out var value))
                return value;
            throw new System.ArgumentException("Unknown person label", nameof(label));
        }
        /// <summary>Try to parse a catalogue label; returns false if unknown or null.</summary>
        public static bool TryParsePerson(string? label, out Person value) {
            foreach (Person item in System.Enum.GetValues(typeof(Person)))
                if (item.Label() == label) {
                    value = item;
                    return true;
                }
            value = default;
            return false;
        }
    }
}
