package com.tmk.immobilier.application.domain.organisation;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/**
 * Client de la plateforme : une agence, un bailleur ou un gestionnaire de
 * patrimoine. Toutes les données métier (biens, locataires, baux, loyers…)
 * lui appartiennent ; son identité est celle du bailleur imprimée sur les
 * contrats et les quittances.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Organisation {

    private Long id;
    private String nom;
    private String representant;
    private String email;
    private String telephone;
    private String adresse;
    /** Ville de signature des documents et juridiction compétente. */
    private String ville;
    /** Code pays ISO 3166-1 alpha-2. */
    private String pays;
    /** Code devise ISO 4217. */
    private String devise;
    private String logoCle;
    private String logoType;

    private PlanAbonnement plan;
    private StatutAbonnement statutAbonnement;
    private LocalDate essaiFinLe;
    private LocalDate abonnementFinLe;
    private boolean historique;

    /** Nouvelle organisation issue d'une inscription : essai gratuit de la formule {@link PlanAbonnement#PLAN_ESSAI}. */
    public static Organisation nouvelleEnEssai(String nom, LocalDate aujourdhui) {
        return Organisation.builder()
                .nom(nom.trim())
                .pays("CI")
                .devise("XOF")
                .plan(PlanAbonnement.PLAN_ESSAI)
                .statutAbonnement(StatutAbonnement.ESSAI)
                .essaiFinLe(aujourdhui.plusDays(PlanAbonnement.JOURS_ESSAI))
                .build();
    }

    /** Droits ouverts par l'abonnement au jour donné. */
    public AccesOrganisation acces(LocalDate aujourdhui) {
        return switch (statutAbonnement) {
            case RESILIE -> AccesOrganisation.BLOQUE;
            case SUSPENDU -> AccesOrganisation.LECTURE_SEULE;
            case ESSAI -> essaiFinLe != null && aujourdhui.isAfter(essaiFinLe)
                    ? AccesOrganisation.LECTURE_SEULE : AccesOrganisation.COMPLET;
            case ACTIF -> abonnementFinLe != null && aujourdhui.isAfter(abonnementFinLe)
                    ? AccesOrganisation.LECTURE_SEULE : AccesOrganisation.COMPLET;
        };
    }

    /** Explication présentable à l'utilisateur quand l'accès n'est pas complet. */
    public String motifRestriction(LocalDate aujourdhui) {
        return switch (statutAbonnement) {
            case RESILIE -> "L'abonnement de « " + nom + " » est résilié.";
            case SUSPENDU -> "L'abonnement de « " + nom + " » est suspendu : les données restent consultables, "
                    + "mais aucune modification n'est possible. Contactez le support.";
            case ESSAI -> "La période d'essai de « " + nom + " » est terminée : choisissez une formule "
                    + "pour continuer à enregistrer des opérations.";
            case ACTIF -> "L'abonnement de « " + nom + " » est arrivé à échéance : renouvelez-le "
                    + "pour continuer à enregistrer des opérations.";
        };
    }

    /** Jours restants avant la fin de l'essai ou de la période payée ; nul si sans échéance. */
    public Long joursRestants(LocalDate aujourdhui) {
        LocalDate fin = statutAbonnement == StatutAbonnement.ESSAI ? essaiFinLe
                : statutAbonnement == StatutAbonnement.ACTIF ? abonnementFinLe : null;
        if (fin == null) return null;
        return Math.max(0, java.time.temporal.ChronoUnit.DAYS.between(aujourdhui, fin));
    }
}
