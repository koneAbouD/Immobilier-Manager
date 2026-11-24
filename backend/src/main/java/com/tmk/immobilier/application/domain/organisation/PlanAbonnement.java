package com.tmk.immobilier.application.domain.organisation;

/**
 * Formules d'abonnement et leurs limites. Un lot est un local louable
 * (appartement, magasin, bureau, terrain…) : c'est l'unité de facturation.
 *
 * <p>{@code null} pour une limite ou un tarif signifie « illimité » / « sur devis ».
 */
public enum PlanAbonnement {

    GRATUIT("Gratuit", 5, 1, 0L),
    ESSENTIEL("Essentiel", 50, 3, 15_000L),
    PROFESSIONNEL("Professionnel", 300, 10, 45_000L),
    ENTREPRISE("Entreprise", null, null, null);

    /** Formule offerte pendant l'essai : toutes les fonctions, limites confortables. */
    public static final PlanAbonnement PLAN_ESSAI = PROFESSIONNEL;

    /** Durée de l'essai gratuit, en jours. */
    public static final int JOURS_ESSAI = 30;

    private final String libelle;
    private final Integer lotsMax;
    private final Integer membresMax;
    /** Tarif mensuel hors taxes, dans la devise de facturation (XOF). */
    private final Long tarifMensuel;

    PlanAbonnement(String libelle, Integer lotsMax, Integer membresMax, Long tarifMensuel) {
        this.libelle = libelle;
        this.lotsMax = lotsMax;
        this.membresMax = membresMax;
        this.tarifMensuel = tarifMensuel;
    }

    public String getLibelle() {
        return libelle;
    }

    public Integer getLotsMax() {
        return lotsMax;
    }

    public Integer getMembresMax() {
        return membresMax;
    }

    public Long getTarifMensuel() {
        return tarifMensuel;
    }

    public boolean autoriseLots(long lotsApresAjout) {
        return lotsMax == null || lotsApresAjout <= lotsMax;
    }

    public boolean autoriseMembres(long membresApresAjout) {
        return membresMax == null || membresApresAjout <= membresMax;
    }
}
