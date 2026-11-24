package com.tmk.immobilier.application.usecases.membre;

import com.tmk.immobilier.application.domain.organisation.Membre;
import com.tmk.immobilier.application.domain.organisation.NouveauMembre;
import com.tmk.immobilier.application.domain.organisation.RoleMembre;
import com.tmk.immobilier.application.domain.organisation.Utilisateur;
import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.identite.GestionIdentitesPort;
import com.tmk.immobilier.application.ports.organisation.OrganisationCourantePort;
import com.tmk.immobilier.application.ports.persistence.MembreRepository;
import com.tmk.immobilier.application.ports.persistence.UtilisateurRepository;
import com.tmk.immobilier.application.usecases.organisation.MotsDePasse;
import com.tmk.immobilier.application.usecases.organisation.QuotasAbonnement;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

/**
 * Équipe de l'organisation courante : invitation, changement de rôle,
 * désactivation, retrait et transmission de la propriété.
 *
 * <p>Règles :
 * <ul>
 *   <li>le propriétaire est unique ; il ne se retire pas, il transmet ;</li>
 *   <li>personne n'agit sur sa propre adhésion (pas d'auto-promotion, pas
 *       d'organisation sans administrateur par mégarde) ;</li>
 *   <li>seul le propriétaire nomme, modifie ou retire un administrateur.</li>
 * </ul>
 */
@RequiredArgsConstructor
public class GestionMembresUseCase {

    private final OrganisationCourantePort organisationCourante;
    private final MembreRepository membreRepository;
    private final UtilisateurRepository utilisateurRepository;
    private final GestionIdentitesPort identites;
    private final QuotasAbonnement quotas;

    @Transactional(readOnly = true)
    public List<Membre> lister() {
        return membreRepository.findByOrganisationId(organisationCourante.id());
    }

    /**
     * Ajoute un collaborateur. Un compte existant (déjà membre d'une autre
     * organisation) est simplement rattaché ; sinon il est créé avec un mot de
     * passe provisoire, renvoyé une seule fois.
     */
    @Transactional
    public NouveauMembre ajouter(String email, String prenom, String nom, RoleMembre role) {
        Long organisationId = organisationCourante.id();
        verifierPeutAttribuer(role);
        String adresse = email.trim().toLowerCase();

        Optional<Utilisateur> connu = utilisateurRepository.findByEmail(adresse);
        if (connu.isPresent()) {
            Optional<Membre> existant = membreRepository.findByOrganisationIdAndUtilisateurId(organisationId, connu.get().getId());
            if (existant.isPresent() && existant.get().isActif()) {
                throw new RegleMetierException("DEJA_MEMBRE", adresse + " fait déjà partie de l'équipe.");
            }
            quotas.verifierAjoutMembre();
            if (existant.isPresent()) {
                Membre membre = existant.get();
                membre.setActif(true);
                membre.setRole(role);
                return new NouveauMembre(membreRepository.save(membre), null);
            }
            return new NouveauMembre(adherer(organisationId, connu.get(), role), null);
        }

        quotas.verifierAjoutMembre();
        String motDePasse = null;
        String keycloakId = identites.trouverParEmail(adresse).orElse(null);
        boolean cree = keycloakId == null;
        if (cree) {
            motDePasse = MotsDePasse.generer();
            keycloakId = identites.creerCompte(adresse, prenom.trim(), nom.trim(), motDePasse);
        }
        try {
            Utilisateur utilisateur = utilisateurRepository.save(Utilisateur.builder()
                    .keycloakId(keycloakId).email(adresse).prenom(prenom.trim()).nom(nom.trim()).build());
            return new NouveauMembre(adherer(organisationId, utilisateur, role), motDePasse);
        } catch (RuntimeException e) {
            if (cree) identites.supprimerCompte(keycloakId);
            throw e;
        }
    }

    @Transactional
    public Membre modifier(Long membreId, RoleMembre role, Boolean actif) {
        Membre membre = membreDeLOrganisation(membreId);
        verifierPeutAgirSur(membre);
        if (role != null && role != membre.getRole()) {
            verifierPeutAttribuer(role);
            membre.setRole(role);
        }
        if (actif != null && actif != membre.isActif()) {
            if (actif) quotas.verifierAjoutMembre();
            membre.setActif(actif);
        }
        return membreRepository.save(membre);
    }

    @Transactional
    public void retirer(Long membreId) {
        Membre membre = membreDeLOrganisation(membreId);
        verifierPeutAgirSur(membre);
        membreRepository.deleteById(membre.getId());
    }

    /** Le propriétaire transmet son rôle à un membre actif ; il devient administrateur. */
    @Transactional
    public Membre transfererPropriete(Long membreId) {
        if (organisationCourante.role().orElse(null) != RoleMembre.PROPRIETAIRE) {
            throw new RegleMetierException("PROPRIETAIRE_REQUIS", "Seul le propriétaire peut transmettre la propriété du compte.");
        }
        Membre cible = membreDeLOrganisation(membreId);
        if (!cible.isActif()) {
            throw new RegleMetierException("MEMBRE_INACTIF", "Réactivez ce membre avant de lui transmettre la propriété.");
        }
        Long moi = organisationCourante.utilisateurId().orElseThrow();
        if (cible.getUtilisateur().getId().equals(moi)) {
            throw new RegleMetierException("DEJA_PROPRIETAIRE", "Vous êtes déjà propriétaire de ce compte.");
        }
        Membre actuel = membreRepository.findByOrganisationIdAndUtilisateurId(organisationCourante.id(), moi).orElseThrow();
        // Dans cet ordre : l'index unique n'admet jamais deux propriétaires.
        actuel.setRole(RoleMembre.ADMIN);
        membreRepository.save(actuel);
        cible.setRole(RoleMembre.PROPRIETAIRE);
        return membreRepository.save(cible);
    }

    private Membre adherer(Long organisationId, Utilisateur utilisateur, RoleMembre role) {
        membreRepository.save(Membre.builder()
                .organisationId(organisationId).utilisateur(utilisateur).role(role).actif(true).build());
        return membreRepository.findByOrganisationIdAndUtilisateurId(organisationId, utilisateur.getId()).orElseThrow();
    }

    private Membre membreDeLOrganisation(Long membreId) {
        return membreRepository.findById(membreId)
                .filter(m -> m.getOrganisationId().equals(organisationCourante.id()))
                .orElseThrow(() -> ResourceNotFoundException.of("Membre", membreId));
    }

    private void verifierPeutAttribuer(RoleMembre role) {
        if (role == RoleMembre.PROPRIETAIRE) {
            throw new RegleMetierException("ROLE_PROPRIETAIRE_RESERVE",
                    "La propriété du compte se transmet, elle ne s'attribue pas.");
        }
        if (role == RoleMembre.ADMIN && organisationCourante.role().orElse(null) != RoleMembre.PROPRIETAIRE) {
            throw new RegleMetierException("PROPRIETAIRE_REQUIS", "Seul le propriétaire peut nommer un administrateur.");
        }
    }

    private void verifierPeutAgirSur(Membre membre) {
        if (membre.estProprietaire()) {
            throw new RegleMetierException("PROPRIETAIRE_PROTEGE",
                    "Le propriétaire du compte ne peut être ni modifié ni retiré : il transmet d'abord la propriété.");
        }
        Long moi = organisationCourante.utilisateurId().orElse(null);
        if (membre.getUtilisateur().getId().equals(moi)) {
            throw new RegleMetierException("ACTION_SUR_SOI", "Vous ne pouvez pas modifier votre propre adhésion.");
        }
        if (membre.getRole() == RoleMembre.ADMIN && organisationCourante.role().orElse(null) != RoleMembre.PROPRIETAIRE) {
            throw new RegleMetierException("PROPRIETAIRE_REQUIS", "Seul le propriétaire peut modifier un administrateur.");
        }
    }
}
