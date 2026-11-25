package com.tmk.immobilier.application.ports.persistence;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.locataire.ComptesSituations;
import com.tmk.immobilier.application.domain.locataire.Locataire;
import com.tmk.immobilier.application.domain.locataire.LocataireResume;
import com.tmk.immobilier.application.domain.locataire.SituationLocataire;

import java.time.LocalDate;
import java.util.Optional;

public interface LocataireRepository {

    Locataire save(Locataire locataire);

    Optional<Locataire> findById(Long id);

    /** @param recherche mot-clé libre (nom, prénom, téléphone) ; ignoré s'il est vide */
    PageResult<Locataire> findPage(String recherche, int page, int size);

    /**
     * Locataires avec leur logement et l'état de leurs loyers au jour donné,
     * les retards en tête puis par nom.
     *
     * @param recherche  nom, prénom, téléphone, e-mail, référence du logement ou nom du bien ; ignoré s'il est vide
     * @param immeubleId facultatif : seuls les locataires ayant un bail actif dans ce bien ; indicateurs
     *                   et logement affiché se limitent alors à ce bien
     * @param situation  filtre facultatif
     */
    PageResult<LocataireResume> findResumes(String recherche, Long immeubleId, SituationLocataire situation,
                                            LocalDate aujourdhui, int page, int size);

    /** Répartition par situation des locataires répondant à la recherche (et au bien, s'il est donné). */
    ComptesSituations compterSituations(String recherche, Long immeubleId, LocalDate aujourdhui);

    boolean existsByTelephone(String telephone);

    boolean existsByTelephoneAndIdNot(String telephone, Long id);

    void deleteById(Long id);
}
