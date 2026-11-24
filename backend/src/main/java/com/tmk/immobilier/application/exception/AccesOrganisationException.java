package com.tmk.immobilier.application.exception;

/**
 * L'appelant ne peut pas agir dans l'organisation demandée : il n'en est pas
 * membre, son adhésion est désactivée, ou l'abonnement ne le permet pas.
 */
public class AccesOrganisationException extends RuntimeException {

    public enum Motif {
        /** Aucune organisation n'a pu être déterminée pour l'appelant. */
        AUCUNE_ORGANISATION,
        /** Plusieurs adhésions : l'en-tête X-Organisation-Id est requis. */
        ORGANISATION_A_PRECISER,
        /** Pas membre (actif) de l'organisation demandée. */
        NON_MEMBRE,
        /** Abonnement en lecture seule : écriture refusée. */
        LECTURE_SEULE,
        /** Abonnement résilié. */
        BLOQUE
    }

    private final Motif motif;

    public AccesOrganisationException(Motif motif, String message) {
        super(message);
        this.motif = motif;
    }

    public Motif getMotif() {
        return motif;
    }
}
