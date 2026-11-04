package com.tmk.immobilier.application.ports.security;

/**
 * Identité de l'utilisateur à l'origine de l'action en cours, archivée sur les
 * annulations et résiliations. Hors requête (scheduler), renvoie « system ».
 */
public interface AuteurCourantPort {

    String auteur();
}
