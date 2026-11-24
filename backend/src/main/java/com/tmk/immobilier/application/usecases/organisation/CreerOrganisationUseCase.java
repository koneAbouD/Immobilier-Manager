package com.tmk.immobilier.application.usecases.organisation;

import com.tmk.immobilier.application.domain.organisation.Membre;
import com.tmk.immobilier.application.domain.organisation.Organisation;
import com.tmk.immobilier.application.domain.organisation.RoleMembre;
import com.tmk.immobilier.application.domain.organisation.Utilisateur;
import com.tmk.immobilier.application.ports.persistence.MembreRepository;
import com.tmk.immobilier.application.ports.persistence.OrganisationRepository;
import com.tmk.immobilier.application.ports.persistence.UtilisateurRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;

/**
 * Volet base de données de l'inscription : l'utilisateur, son organisation en
 * essai et son adhésion de propriétaire, dans une seule transaction.
 */
@RequiredArgsConstructor
public class CreerOrganisationUseCase {

    private final OrganisationRepository organisationRepository;
    private final UtilisateurRepository utilisateurRepository;
    private final MembreRepository membreRepository;

    @Transactional
    public Organisation execute(String nomOrganisation, String telephone, Utilisateur proprietaire) {
        Utilisateur utilisateur = utilisateurRepository.save(proprietaire);
        Organisation organisation = Organisation.nouvelleEnEssai(nomOrganisation, LocalDate.now());
        organisation.setEmail(utilisateur.getEmail());
        organisation.setTelephone(telephone);
        organisation.setRepresentant(utilisateur.nomComplet());
        Organisation saved = organisationRepository.save(organisation);
        membreRepository.save(Membre.builder()
                .organisationId(saved.getId())
                .utilisateur(utilisateur)
                .role(RoleMembre.PROPRIETAIRE)
                .actif(true)
                .build());
        return saved;
    }
}
