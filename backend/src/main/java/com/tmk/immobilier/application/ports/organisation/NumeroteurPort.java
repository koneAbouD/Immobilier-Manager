package com.tmk.immobilier.application.ports.organisation;

/** Numérotation continue, propre à chaque organisation (BAIL-00001, BAIL-00002…). */
public interface NumeroteurPort {

    /** Valeur suivante du compteur [nom] de l'organisation courante, sans trou ni doublon. */
    long prochain(String nom);
}
