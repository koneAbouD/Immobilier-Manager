package com.tmk.immobilier.application.domain.journal;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * Valeurs lisibles d'une donnée à un instant, champ par champ et dans l'ordre
 * de la fiche. Pris avant et après une modification, deux instantanés donnent
 * la liste des changements à tracer.
 */
public final class Instantane {

    private final Map<String, String> champs = new LinkedHashMap<>();

    /** Ajoute un champ ; une valeur vide compte comme « non renseigné ». */
    public Instantane avec(String champ, Object valeur) {
        String texte = valeur == null ? null : valeur.toString().trim();
        champs.put(champ, texte == null || texte.isEmpty() ? null : texte);
        return this;
    }

    public Map<String, String> champs() {
        return Collections.unmodifiableMap(champs);
    }

    /** Champs dont la valeur diffère entre [avant] et [apres], dans l'ordre de la fiche. */
    public static List<Changement> differences(Instantane avant, Instantane apres) {
        List<Changement> changements = new ArrayList<>();
        apres.champs.forEach((champ, valeur) -> {
            String ancienne = avant.champs.get(champ);
            if (!Objects.equals(ancienne, valeur)) changements.add(new Changement(champ, ancienne, valeur));
        });
        return changements;
    }

    /** Dernières valeurs connues d'une donnée supprimée (champs renseignés seulement). */
    public List<Changement> enSuppression() {
        return champs.entrySet().stream()
                .filter(e -> e.getValue() != null)
                .map(e -> new Changement(e.getKey(), e.getValue(), null))
                .toList();
    }
}
