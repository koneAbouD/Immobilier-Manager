package com.tmk.immobilier.infrastructure.persistence.postgresql.mapper;

import com.tmk.immobilier.application.domain.organisation.Membre;
import com.tmk.immobilier.application.domain.organisation.Organisation;
import com.tmk.immobilier.application.domain.organisation.Utilisateur;
import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.MembreEntity;
import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.OrganisationEntity;
import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.UtilisateurEntity;
import org.springframework.stereotype.Component;

/**
 * Conversions des tables globales (organisations, utilisateurs, membres).
 * Écrites à la main : peu de champs, et des associations qu'on ne veut jamais
 * recopier par mégarde vers l'entité (l'organisation d'une adhésion ne change pas).
 */
@Component
public class OrganisationPersistenceMapper {

    public Organisation toDomain(OrganisationEntity e) {
        if (e == null) return null;
        return Organisation.builder()
                .id(e.getId())
                .nom(e.getNom())
                .representant(e.getRepresentant())
                .email(e.getEmail())
                .telephone(e.getTelephone())
                .adresse(e.getAdresse())
                .ville(e.getVille())
                .pays(e.getPays())
                .devise(e.getDevise())
                .logoCle(e.getLogoCle())
                .logoType(e.getLogoType())
                .plan(e.getPlan())
                .statutAbonnement(e.getStatutAbonnement())
                .essaiFinLe(e.getEssaiFinLe())
                .abonnementFinLe(e.getAbonnementFinLe())
                .historique(e.isHistorique())
                .build();
    }

    /** Recopie le domaine dans [cible] ; « historique » n'est jamais modifiable par l'application. */
    public OrganisationEntity copier(Organisation d, OrganisationEntity cible) {
        cible.setNom(d.getNom());
        cible.setRepresentant(d.getRepresentant());
        cible.setEmail(d.getEmail());
        cible.setTelephone(d.getTelephone());
        cible.setAdresse(d.getAdresse());
        cible.setVille(d.getVille());
        cible.setPays(d.getPays() != null ? d.getPays() : "CI");
        cible.setDevise(d.getDevise() != null ? d.getDevise() : "XOF");
        cible.setLogoCle(d.getLogoCle());
        cible.setLogoType(d.getLogoType());
        cible.setPlan(d.getPlan());
        cible.setStatutAbonnement(d.getStatutAbonnement());
        cible.setEssaiFinLe(d.getEssaiFinLe());
        cible.setAbonnementFinLe(d.getAbonnementFinLe());
        return cible;
    }

    public Utilisateur toDomain(UtilisateurEntity e) {
        if (e == null) return null;
        return Utilisateur.builder()
                .id(e.getId())
                .keycloakId(e.getKeycloakId())
                .email(e.getEmail())
                .prenom(e.getPrenom())
                .nom(e.getNom())
                .telephone(e.getTelephone())
                .derniereConnexion(e.getDerniereConnexion())
                .build();
    }

    public UtilisateurEntity copier(Utilisateur d, UtilisateurEntity cible) {
        cible.setKeycloakId(d.getKeycloakId());
        cible.setEmail(d.getEmail());
        cible.setPrenom(d.getPrenom());
        cible.setNom(d.getNom());
        cible.setTelephone(d.getTelephone());
        cible.setDerniereConnexion(d.getDerniereConnexion());
        return cible;
    }

    public Membre toDomain(MembreEntity e) {
        if (e == null) return null;
        return Membre.builder()
                .id(e.getId())
                .organisationId(e.getOrganisation().getId())
                .organisation(toDomain(e.getOrganisation()))
                .utilisateur(toDomain(e.getUtilisateur()))
                .role(e.getRole())
                .actif(e.isActif())
                .ajouteLe(e.getCreatedAt())
                .build();
    }
}
