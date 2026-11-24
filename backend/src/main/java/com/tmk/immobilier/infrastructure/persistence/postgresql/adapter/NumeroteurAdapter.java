package com.tmk.immobilier.infrastructure.persistence.postgresql.adapter;

import com.tmk.immobilier.application.ports.organisation.NumeroteurPort;
import com.tmk.immobilier.application.ports.organisation.OrganisationCourantePort;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * Compteur par organisation, incrémenté en une seule instruction atomique : la
 * ligne est verrouillée jusqu'à la fin de la transaction appelante, deux
 * créations simultanées obtiennent donc deux numéros distincts, et une
 * création annulée rend son numéro.
 */
@Component
@RequiredArgsConstructor
public class NumeroteurAdapter implements NumeroteurPort {

    private static final String SUIVANT = """
            INSERT INTO compteurs_organisation (organisation_id, nom, valeur)
            VALUES (:organisation, :nom, 1)
            ON CONFLICT (organisation_id, nom)
            DO UPDATE SET valeur = compteurs_organisation.valeur + 1
            RETURNING valeur
            """;

    private final NamedParameterJdbcTemplate jdbc;
    private final OrganisationCourantePort organisationCourante;

    @Override
    public long prochain(String nom) {
        Long valeur = jdbc.queryForObject(SUIVANT, new MapSqlParameterSource()
                .addValue("organisation", organisationCourante.id())
                .addValue("nom", nom), Long.class);
        if (valeur == null) throw new IllegalStateException("Compteur " + nom + " indisponible");
        return valeur;
    }
}
