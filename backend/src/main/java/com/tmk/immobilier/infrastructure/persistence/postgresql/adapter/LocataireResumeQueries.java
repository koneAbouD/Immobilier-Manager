package com.tmk.immobilier.infrastructure.persistence.postgresql.adapter;

import com.tmk.immobilier.application.domain.locataire.SituationLocataire;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;

import java.time.LocalDate;

/**
 * Requêtes SQL du résumé des locataires. Trop d'agrégats croisés (baux actifs,
 * loyers échus, logement courant) pour une Specification : on les écrit en SQL
 * et on recharge ensuite les locataires de la page par leurs identifiants.
 */
final class LocataireResumeQueries {

    private LocataireResumeQueries() {
    }

    /** Une ligne par locataire : indicateurs, logement du bail actif le plus récent et situation. */
    private static final String SITUATIONS = """
            WITH stats AS (
                SELECT l.id, l.nom, l.prenom,
                       (SELECT count(*) FROM baux b
                         WHERE b.locataire_id = l.id AND b.statut = 'ACTIF') AS baux_actifs,
                       (SELECT count(*) FROM baux b
                         WHERE b.locataire_id = l.id AND b.statut = 'ACTIF'
                           AND b.contrat_signe_cle IS NULL) AS contrats_a_signer,
                       (SELECT coalesce(sum(e.montant_du - e.montant_paye), 0)
                          FROM echeances_loyer e JOIN baux b ON b.id = e.bail_id
                         WHERE b.locataire_id = l.id AND e.statut IN ('A_PAYER', 'PARTIEL')
                           AND e.date_echeance < :aujourdhui) AS montant_retard,
                       (SELECT min(e.date_echeance)
                          FROM echeances_loyer e JOIN baux b ON b.id = e.bail_id
                         WHERE b.locataire_id = l.id AND e.statut IN ('A_PAYER', 'PARTIEL')
                           AND e.date_echeance < :aujourdhui) AS plus_ancien_retard
                  FROM locataires l
                 WHERE %s
            ), situations AS (
                SELECT s.*,
                       CASE WHEN s.montant_retard > 0 THEN 'EN_RETARD'
                            WHEN s.baux_actifs > 0 THEN 'A_JOUR'
                            ELSE 'SANS_BAIL' END AS situation
                  FROM stats s
            )
            """;

    private static final String RECHERCHE = """
            (lower(l.nom) LIKE :motif ESCAPE '\\' OR lower(l.prenom) LIKE :motif ESCAPE '\\'
             OR lower(l.prenom || ' ' || l.nom) LIKE :motif ESCAPE '\\'
             OR lower(l.telephone) LIKE :motif ESCAPE '\\' OR lower(coalesce(l.email, '')) LIKE :motif ESCAPE '\\'
             OR EXISTS (SELECT 1 FROM baux b JOIN appartements a ON a.id = b.appartement_id
                         WHERE b.locataire_id = l.id AND b.statut = 'ACTIF'
                           AND lower(a.reference) LIKE :motif ESCAPE '\\'))
            """;

    static String page(boolean avecRecherche, boolean avecSituation) {
        return situations(avecRecherche) + """
                SELECT s.id, s.situation, s.baux_actifs, s.contrats_a_signer, s.montant_retard,
                       s.plus_ancien_retard, lg.reference AS logement_reference, lg.type AS logement_type,
                       lg.immeuble AS immeuble_nom
                  FROM situations s
                  LEFT JOIN LATERAL (
                       SELECT a.reference, a.type, i.nom AS immeuble
                         FROM baux b
                         JOIN appartements a ON a.id = b.appartement_id
                         JOIN immeubles i ON i.id = a.immeuble_id
                        WHERE b.locataire_id = s.id AND b.statut = 'ACTIF'
                        ORDER BY b.date_debut DESC, b.id DESC
                        LIMIT 1) lg ON true
                """ + (avecSituation ? " WHERE s.situation = :situation" : "") + """

                 ORDER BY CASE s.situation WHEN 'EN_RETARD' THEN 0 WHEN 'A_JOUR' THEN 1 ELSE 2 END,
                          lower(s.nom), lower(s.prenom), s.id
                 LIMIT :size OFFSET :offset
                """;
    }

    static String total(boolean avecRecherche, boolean avecSituation) {
        return situations(avecRecherche) + "SELECT count(*) FROM situations s"
                + (avecSituation ? " WHERE s.situation = :situation" : "");
    }

    static String comptes(boolean avecRecherche) {
        return situations(avecRecherche) + "SELECT s.situation, count(*) AS nombre FROM situations s GROUP BY s.situation";
    }

    static MapSqlParameterSource parametres(String recherche, SituationLocataire situation, LocalDate aujourdhui) {
        MapSqlParameterSource params = new MapSqlParameterSource("aujourdhui", aujourdhui);
        if (aRecherche(recherche)) params.addValue("motif", motif(recherche));
        if (situation != null) params.addValue("situation", situation.name());
        return params;
    }

    static boolean aRecherche(String recherche) {
        return recherche != null && !recherche.isBlank();
    }

    private static String situations(boolean avecRecherche) {
        return SITUATIONS.formatted(avecRecherche ? RECHERCHE : "true");
    }

    /** Motif LIKE insensible à la casse, jokers saisis par l'utilisateur neutralisés. */
    private static String motif(String recherche) {
        String echappe = recherche.trim().toLowerCase()
                .replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
        return "%" + echappe + "%";
    }
}
