package com.tmk.immobilier.application.usecases.organisation;

import com.tmk.immobilier.application.domain.organisation.Organisation;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.organisation.OrganisationCourantePort;
import com.tmk.immobilier.application.ports.persistence.OrganisationRepository;
import com.tmk.immobilier.application.usecases.locataire.TelephoneNormalizer;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

/** Identité de l'organisation (bailleur des contrats et quittances). L'abonnement ne se modifie pas ici. */
@RequiredArgsConstructor
public class UpdateOrganisationUseCase {

    private final OrganisationCourantePort organisationCourante;
    private final OrganisationRepository organisationRepository;

    @Transactional
    public Organisation execute(Organisation modifications) {
        Long id = organisationCourante.id();
        Organisation organisation = organisationRepository.findById(id)
                .orElseThrow(() -> ResourceNotFoundException.of("Organisation", id));
        organisation.setNom(modifications.getNom().trim());
        organisation.setRepresentant(vide(modifications.getRepresentant()));
        organisation.setEmail(vide(modifications.getEmail()) == null ? null : modifications.getEmail().trim().toLowerCase());
        organisation.setTelephone(vide(modifications.getTelephone()) == null
                ? null : TelephoneNormalizer.normaliser(modifications.getTelephone()));
        organisation.setAdresse(vide(modifications.getAdresse()));
        organisation.setVille(vide(modifications.getVille()));
        if (modifications.getPays() != null) organisation.setPays(modifications.getPays().toUpperCase());
        if (modifications.getDevise() != null) organisation.setDevise(modifications.getDevise().toUpperCase());
        return organisationRepository.save(organisation);
    }

    private static String vide(String valeur) {
        return valeur == null || valeur.isBlank() ? null : valeur.trim();
    }
}
