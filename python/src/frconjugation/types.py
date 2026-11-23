"""Typed grammatical labels matching the Swift public API."""

from enum import Enum


class Voice(str, Enum):
    """French grammatical voice; values are catalogue labels."""

    ACTIVE_AVOIR = "voix_active_avoir"
    """voix_active_avoir."""
    ACTIVE_ETRE = "voix_active_etre"
    """voix_active_etre."""
    ACTIVE = "voix_active"
    """voix_active."""
    PASSIVE = "voix_passive"
    """voix_passive."""
    PRONOMINAL = "voix_prono"
    """voix_prono."""


class Mode(str, Enum):
    """French grammatical mode; values are catalogue labels."""

    INDICATIF = "indicatif"
    """indicatif."""
    SUBJONCTIF = "subjonctif"
    """subjonctif."""
    CONDITIONNEL = "conditionnel"
    """conditionnel."""
    IMPERATIF = "imperatif"
    """imperatif."""
    PARTICIPE = "participe"
    """participe."""


class Tense(str, Enum):
    """French grammatical tense; values are catalogue labels."""

    PRESENT = "present"
    """present."""
    IMPARFAIT = "imparfait"
    """imparfait."""
    PASSE_SIMPLE = "passe_simple"
    """passe_simple."""
    FUTUR_SIMPLE = "futur_simple"
    """futur_simple."""
    PASSE_COMPOSE = "passe_compose"
    """passe_compose."""
    PLUS_QUE_PARFAIT = "plus_que_parfait"
    """plus_que_parfait."""
    PASSE_ANTERIEUR = "passe_anterieur"
    """passe_anterieur."""
    FUTUR_ANTERIEUR = "futur_anterieur"
    """futur_anterieur."""
    PASSE = "passe"
    """passe."""
    PASSE_MASCULIN_SINGULIER = "passe_sm"
    """passe_sm."""
    PASSE_FEMININ_SINGULIER = "passe_sf"
    """passe_sf."""
    PASSE_MASCULIN_PLURIEL = "passe_pm"
    """passe_pm."""
    PASSE_FEMININ_PLURIEL = "passe_pf"
    """passe_pf."""
    PASSE_COMPOUND_MASCULIN_SINGULIER = "passe_compound_sm"
    """passe_compound_sm."""
    PASSE_COMPOUND_FEMININ_SINGULIER = "passe_compound_sf"
    """passe_compound_sf."""
    PASSE_COMPOUND_MASCULIN_PLURIEL = "passe_compound_pm"
    """passe_compound_pm."""
    PASSE_COMPOUND_FEMININ_PLURIEL = "passe_compound_pf"
    """passe_compound_pf."""
    PRESENT_MASCULIN_SINGULIER = "present_sm"
    """present_sm."""
    PRESENT_FEMININ_SINGULIER = "present_sf"
    """present_sf."""
    PRESENT_MASCULIN_PLURIEL = "present_pm"
    """present_pm."""
    PRESENT_FEMININ_PLURIEL = "present_pf"
    """present_pf."""
    GERONDIF_PRESENT = "gerondif_present"
    """gerondif_present."""
    GERONDIF_PASSE_MASCULIN_SINGULIER = "gerondif_passe_sm"
    """gerondif_passe_sm."""
    GERONDIF_PASSE_FEMININ_SINGULIER = "gerondif_passe_sf"
    """gerondif_passe_sf."""
    GERONDIF_PASSE_MASCULIN_PLURIEL = "gerondif_passe_pm"
    """gerondif_passe_pm."""
    GERONDIF_PASSE_FEMININ_PLURIEL = "gerondif_passe_pf"
    """gerondif_passe_pf."""


class Person(str, Enum):
    """French grammatical person; values are catalogue labels."""

    FIRST_SINGULAR_MASCULINE = "1sm"
    """1sm."""
    FIRST_SINGULAR_FEMININE = "1sf"
    """1sf."""
    SECOND_SINGULAR_MASCULINE = "2sm"
    """2sm."""
    SECOND_SINGULAR_FEMININE = "2sf"
    """2sf."""
    THIRD_SINGULAR_MASCULINE = "3sm"
    """3sm."""
    THIRD_SINGULAR_FEMININE = "3sf"
    """3sf."""
    THIRD_SINGULAR_NEUTRAL = "3sn"
    """3sn."""
    FIRST_PLURAL_MASCULINE = "1pm"
    """1pm."""
    FIRST_PLURAL_FEMININE = "1pf"
    """1pf."""
    SECOND_PLURAL_MASCULINE = "2pm"
    """2pm."""
    SECOND_PLURAL_FEMININE = "2pf"
    """2pf."""
    THIRD_PLURAL_MASCULINE = "3pm"
    """3pm."""
    THIRD_PLURAL_FEMININE = "3pf"
    """3pf."""

    @property
    def short_label(self) -> str:
        """Compact catalogue person label, such as 1sm."""
        return self.value

    @property
    def pronoun(self) -> str:
        """French subject pronoun without contextual elision."""
        return {
            "1s": "je",
            "2s": "tu",
            "3sm": "il",
            "3sf": "elle",
            "3sn": "on",
            "1p": "nous",
            "2p": "vous",
            "3pm": "ils",
            "3pf": "elles",
        }.get(
            self.value, {"1s": "je", "2s": "tu", "1p": "nous", "2p": "vous"}.get(self.value[:2], "")
        )
