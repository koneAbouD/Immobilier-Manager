package com.tmk.immobilier.infrastructure.config;

import com.tmk.immobilier.application.ports.auth.KeycloakAuthPort;
import com.tmk.immobilier.application.ports.document.ContratBailGenerateurPort;
import com.tmk.immobilier.application.ports.document.QuittanceGenerateurPort;
import com.tmk.immobilier.application.ports.document.StockageDocumentsPort;
import com.tmk.immobilier.application.ports.identite.GestionIdentitesPort;
import com.tmk.immobilier.application.ports.organisation.NumeroteurPort;
import com.tmk.immobilier.application.ports.organisation.OrganisationCourantePort;
import com.tmk.immobilier.application.ports.persistence.AppartementRepository;
import com.tmk.immobilier.application.ports.persistence.BailRepository;
import com.tmk.immobilier.application.ports.persistence.EcheanceLoyerRepository;
import com.tmk.immobilier.application.ports.persistence.ImmeubleRepository;
import com.tmk.immobilier.application.ports.persistence.LocataireRepository;
import com.tmk.immobilier.application.ports.persistence.MaintenanceRepository;
import com.tmk.immobilier.application.ports.persistence.MembreRepository;
import com.tmk.immobilier.application.ports.persistence.OrganisationRepository;
import com.tmk.immobilier.application.ports.persistence.PaiementLoyerRepository;
import com.tmk.immobilier.application.ports.persistence.PhotoBienRepository;
import com.tmk.immobilier.application.ports.persistence.UtilisateurRepository;
import com.tmk.immobilier.application.ports.security.AuteurCourantPort;
import com.tmk.immobilier.application.usecases.appartement.*;
import com.tmk.immobilier.application.usecases.auth.LoginUseCase;
import com.tmk.immobilier.application.usecases.auth.LogoutUseCase;
import com.tmk.immobilier.application.usecases.auth.RefreshTokenUseCase;
import com.tmk.immobilier.application.usecases.bail.*;
import com.tmk.immobilier.application.usecases.contrat.*;
import com.tmk.immobilier.application.usecases.immeuble.*;
import com.tmk.immobilier.application.usecases.locataire.*;
import com.tmk.immobilier.application.usecases.loyer.*;
import com.tmk.immobilier.application.usecases.maintenance.*;
import com.tmk.immobilier.application.usecases.membre.GestionMembresUseCase;
import com.tmk.immobilier.application.usecases.organisation.*;
import com.tmk.immobilier.application.usecases.plateforme.AdministrationPlateformeUseCase;
import com.tmk.immobilier.application.usecases.tableaubord.GetTableauBordUseCase;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Déclaration des use cases. Ils restent de simples classes Java, sans
 * annotation de stéréotype : la couche application ne dépend pas du
 * conteneur, et chaque dépendance est visible ici, au même endroit.
 */
@Configuration
public class UseCaseBeanConfiguration {

    // ----- Auth -----
    @Bean
    public LoginUseCase loginUseCase(KeycloakAuthPort port) {
        return new LoginUseCase(port);
    }

    @Bean
    public RefreshTokenUseCase refreshTokenUseCase(KeycloakAuthPort port) {
        return new RefreshTokenUseCase(port);
    }

    @Bean
    public LogoutUseCase logoutUseCase(KeycloakAuthPort port) {
        return new LogoutUseCase(port);
    }

    // ----- Organisations, comptes et abonnements -----
    @Bean
    public QuotasAbonnement quotasAbonnement(OrganisationCourantePort organisationCourante,
                                             OrganisationRepository organisationRepo) {
        return new QuotasAbonnement(organisationCourante, organisationRepo);
    }

    @Bean
    public ComptesUtilisateurs comptesUtilisateurs(UtilisateurRepository utilisateurRepo,
                                                   MembreRepository membreRepo,
                                                   OrganisationRepository organisationRepo) {
        return new ComptesUtilisateurs(utilisateurRepo, membreRepo, organisationRepo);
    }

    @Bean
    public ResoudreAccesUseCase resoudreAccesUseCase(ComptesUtilisateurs comptes) {
        return new ResoudreAccesUseCase(comptes);
    }

    @Bean
    public GetMonProfilUseCase getMonProfilUseCase(ComptesUtilisateurs comptes) {
        return new GetMonProfilUseCase(comptes);
    }

    @Bean
    public CreerOrganisationUseCase creerOrganisationUseCase(OrganisationRepository organisationRepo,
                                                             UtilisateurRepository utilisateurRepo,
                                                             MembreRepository membreRepo) {
        return new CreerOrganisationUseCase(organisationRepo, utilisateurRepo, membreRepo);
    }

    @Bean
    public InscrireOrganisationUseCase inscrireOrganisationUseCase(GestionIdentitesPort identites,
                                                                   UtilisateurRepository utilisateurRepo,
                                                                   CreerOrganisationUseCase creerOrganisation,
                                                                   KeycloakAuthPort authPort) {
        return new InscrireOrganisationUseCase(identites, utilisateurRepo, creerOrganisation, authPort);
    }

    @Bean
    public ChangerMotDePasseUseCase changerMotDePasseUseCase(KeycloakAuthPort authPort, GestionIdentitesPort identites) {
        return new ChangerMotDePasseUseCase(authPort, identites);
    }

    @Bean
    public GetOrganisationCouranteUseCase getOrganisationCouranteUseCase(OrganisationCourantePort organisationCourante,
                                                                         OrganisationRepository organisationRepo) {
        return new GetOrganisationCouranteUseCase(organisationCourante, organisationRepo);
    }

    @Bean
    public UpdateOrganisationUseCase updateOrganisationUseCase(OrganisationCourantePort organisationCourante,
                                                               OrganisationRepository organisationRepo) {
        return new UpdateOrganisationUseCase(organisationCourante, organisationRepo);
    }

    @Bean
    public LogoOrganisationUseCase logoOrganisationUseCase(OrganisationCourantePort organisationCourante,
                                                           OrganisationRepository organisationRepo,
                                                           StockageDocumentsPort stockage) {
        return new LogoOrganisationUseCase(organisationCourante, organisationRepo, stockage);
    }

    @Bean
    public GestionMembresUseCase gestionMembresUseCase(OrganisationCourantePort organisationCourante,
                                                       MembreRepository membreRepo,
                                                       UtilisateurRepository utilisateurRepo,
                                                       GestionIdentitesPort identites,
                                                       QuotasAbonnement quotas) {
        return new GestionMembresUseCase(organisationCourante, membreRepo, utilisateurRepo, identites, quotas);
    }

    @Bean
    public AdministrationPlateformeUseCase administrationPlateformeUseCase(OrganisationRepository organisationRepo) {
        return new AdministrationPlateformeUseCase(organisationRepo);
    }

    // ----- Immeubles -----
    @Bean
    public CreateImmeubleUseCase createImmeubleUseCase(ImmeubleRepository immeubleRepo,
                                                       AppartementRepository appartementRepo,
                                                       QuotasAbonnement quotas) {
        return new CreateImmeubleUseCase(immeubleRepo, appartementRepo, quotas);
    }

    @Bean
    public UpdateImmeubleUseCase updateImmeubleUseCase(ImmeubleRepository immeubleRepo) {
        return new UpdateImmeubleUseCase(immeubleRepo);
    }

    @Bean
    public DeleteImmeubleUseCase deleteImmeubleUseCase(ImmeubleRepository immeubleRepo,
                                                       AppartementRepository appartementRepo,
                                                       MaintenanceRepository maintenanceRepo,
                                                       BailRepository bailRepo,
                                                       PhotoBienRepository photoRepo,
                                                       StockageDocumentsPort stockage) {
        return new DeleteImmeubleUseCase(immeubleRepo, appartementRepo, maintenanceRepo, bailRepo, photoRepo, stockage);
    }

    @Bean
    public AjouterPhotoBienUseCase ajouterPhotoBienUseCase(ImmeubleRepository immeubleRepo,
                                                           PhotoBienRepository photoRepo,
                                                           StockageDocumentsPort stockage,
                                                           OrganisationCourantePort organisationCourante) {
        return new AjouterPhotoBienUseCase(immeubleRepo, photoRepo, stockage, organisationCourante);
    }

    @Bean
    public PhotosBienUseCase photosBienUseCase(PhotoBienRepository photoRepo, StockageDocumentsPort stockage) {
        return new PhotosBienUseCase(photoRepo, stockage);
    }

    @Bean
    public GetImmeubleByIdUseCase getImmeubleByIdUseCase(ImmeubleRepository immeubleRepo,
                                                         AppartementRepository appartementRepo) {
        return new GetImmeubleByIdUseCase(immeubleRepo, appartementRepo);
    }

    @Bean
    public GetImmeublesUseCase getImmeublesUseCase(ImmeubleRepository immeubleRepo,
                                                   AppartementRepository appartementRepo) {
        return new GetImmeublesUseCase(immeubleRepo, appartementRepo);
    }

    // ----- Appartements -----
    @Bean
    public CreateAppartementUseCase createAppartementUseCase(AppartementRepository appartementRepo,
                                                             ImmeubleRepository immeubleRepo,
                                                             QuotasAbonnement quotas) {
        return new CreateAppartementUseCase(appartementRepo, immeubleRepo, quotas);
    }

    @Bean
    public UpdateAppartementUseCase updateAppartementUseCase(AppartementRepository appartementRepo) {
        return new UpdateAppartementUseCase(appartementRepo);
    }

    @Bean
    public DeleteAppartementUseCase deleteAppartementUseCase(AppartementRepository appartementRepo,
                                                             BailRepository bailRepo,
                                                             MaintenanceRepository maintenanceRepo) {
        return new DeleteAppartementUseCase(appartementRepo, bailRepo, maintenanceRepo);
    }

    @Bean
    public GetAppartementByIdUseCase getAppartementByIdUseCase(AppartementRepository appartementRepo) {
        return new GetAppartementByIdUseCase(appartementRepo);
    }

    @Bean
    public GetAppartementsUseCase getAppartementsUseCase(AppartementRepository appartementRepo) {
        return new GetAppartementsUseCase(appartementRepo);
    }

    // ----- Locataires -----
    @Bean
    public CreateLocataireUseCase createLocataireUseCase(LocataireRepository locataireRepo) {
        return new CreateLocataireUseCase(locataireRepo);
    }

    @Bean
    public UpdateLocataireUseCase updateLocataireUseCase(LocataireRepository locataireRepo) {
        return new UpdateLocataireUseCase(locataireRepo);
    }

    @Bean
    public DeleteLocataireUseCase deleteLocataireUseCase(LocataireRepository locataireRepo,
                                                         BailRepository bailRepo) {
        return new DeleteLocataireUseCase(locataireRepo, bailRepo);
    }

    @Bean
    public GetLocataireByIdUseCase getLocataireByIdUseCase(LocataireRepository locataireRepo) {
        return new GetLocataireByIdUseCase(locataireRepo);
    }

    @Bean
    public GetLocatairesUseCase getLocatairesUseCase(LocataireRepository locataireRepo) {
        return new GetLocatairesUseCase(locataireRepo);
    }

    @Bean
    public GetLocataireResumesUseCase getLocataireResumesUseCase(LocataireRepository locataireRepo) {
        return new GetLocataireResumesUseCase(locataireRepo);
    }

    @Bean
    public DeposerPieceIdentiteUseCase deposerPieceIdentiteUseCase(LocataireRepository locataireRepo,
                                                                   StockageDocumentsPort stockage,
                                                                   OrganisationCourantePort organisationCourante,
                                                                   AuteurCourantPort auteurCourant) {
        return new DeposerPieceIdentiteUseCase(locataireRepo, stockage, organisationCourante, auteurCourant);
    }

    @Bean
    public GetPieceIdentiteUseCase getPieceIdentiteUseCase(LocataireRepository locataireRepo,
                                                           StockageDocumentsPort stockage) {
        return new GetPieceIdentiteUseCase(locataireRepo, stockage);
    }

    // ----- Loyers -----
    @Bean
    public GenererEcheancesUseCase genererEcheancesUseCase(BailRepository bailRepo,
                                                           EcheanceLoyerRepository echeanceRepo) {
        return new GenererEcheancesUseCase(bailRepo, echeanceRepo);
    }

    @Bean
    public EnregistrerPaiementUseCase enregistrerPaiementUseCase(EcheanceLoyerRepository echeanceRepo,
                                                                 PaiementLoyerRepository paiementRepo) {
        return new EnregistrerPaiementUseCase(echeanceRepo, paiementRepo);
    }

    @Bean
    public AnnulerPaiementUseCase annulerPaiementUseCase(PaiementLoyerRepository paiementRepo,
                                                         EcheanceLoyerRepository echeanceRepo,
                                                         AuteurCourantPort auteurCourant) {
        return new AnnulerPaiementUseCase(paiementRepo, echeanceRepo, auteurCourant);
    }

    @Bean
    public GetEcheancesUseCase getEcheancesUseCase(EcheanceLoyerRepository echeanceRepo) {
        return new GetEcheancesUseCase(echeanceRepo);
    }

    @Bean
    public GetPaiementsUseCase getPaiementsUseCase(PaiementLoyerRepository paiementRepo) {
        return new GetPaiementsUseCase(paiementRepo);
    }

    @Bean
    public GenererQuittanceUseCase genererQuittanceUseCase(PaiementLoyerRepository paiementRepo,
                                                           QuittanceGenerateurPort generateur,
                                                           OrganisationCourantePort organisationCourante,
                                                           OrganisationRepository organisationRepo) {
        return new GenererQuittanceUseCase(paiementRepo, generateur, organisationCourante, organisationRepo);
    }

    // ----- Baux -----
    @Bean
    public CreateBailUseCase createBailUseCase(BailRepository bailRepo,
                                               AppartementRepository appartementRepo,
                                               LocataireRepository locataireRepo,
                                               GenererEcheancesUseCase genererEcheancesUseCase,
                                               NumeroteurPort numeroteur) {
        return new CreateBailUseCase(bailRepo, appartementRepo, locataireRepo, genererEcheancesUseCase, numeroteur);
    }

    @Bean
    public UpdateBailUseCase updateBailUseCase(BailRepository bailRepo, EcheanceLoyerRepository echeanceRepo) {
        return new UpdateBailUseCase(bailRepo, echeanceRepo);
    }

    @Bean
    public ResilierBailUseCase resilierBailUseCase(BailRepository bailRepo,
                                                   AppartementRepository appartementRepo,
                                                   EcheanceLoyerRepository echeanceRepo,
                                                   AuteurCourantPort auteurCourant) {
        return new ResilierBailUseCase(bailRepo, appartementRepo, echeanceRepo, auteurCourant);
    }

    @Bean
    public GetBailByIdUseCase getBailByIdUseCase(BailRepository bailRepo) {
        return new GetBailByIdUseCase(bailRepo);
    }

    @Bean
    public GetBauxUseCase getBauxUseCase(BailRepository bailRepo) {
        return new GetBauxUseCase(bailRepo);
    }

    // ----- Contrats de bail -----
    @Bean
    public GenererContratBailUseCase genererContratBailUseCase(BailRepository bailRepo,
                                                               ContratBailGenerateurPort generateur,
                                                               OrganisationCourantePort organisationCourante,
                                                               OrganisationRepository organisationRepo) {
        return new GenererContratBailUseCase(bailRepo, generateur, organisationCourante, organisationRepo);
    }

    @Bean
    public DeposerContratSigneUseCase deposerContratSigneUseCase(BailRepository bailRepo,
                                                                 StockageDocumentsPort stockage,
                                                                 OrganisationCourantePort organisationCourante,
                                                                 AuteurCourantPort auteurCourant) {
        return new DeposerContratSigneUseCase(bailRepo, stockage, organisationCourante, auteurCourant);
    }

    @Bean
    public GetContratSigneUseCase getContratSigneUseCase(BailRepository bailRepo, StockageDocumentsPort stockage) {
        return new GetContratSigneUseCase(bailRepo, stockage);
    }

    // ----- Maintenances -----
    @Bean
    public SignalerMaintenanceUseCase signalerMaintenanceUseCase(MaintenanceRepository maintenanceRepo,
                                                                 ImmeubleRepository immeubleRepo,
                                                                 AppartementRepository appartementRepo) {
        return new SignalerMaintenanceUseCase(maintenanceRepo, immeubleRepo, appartementRepo);
    }

    @Bean
    public UpdateMaintenanceUseCase updateMaintenanceUseCase(MaintenanceRepository maintenanceRepo,
                                                             ImmeubleRepository immeubleRepo,
                                                             AppartementRepository appartementRepo) {
        return new UpdateMaintenanceUseCase(maintenanceRepo, immeubleRepo, appartementRepo);
    }

    @Bean
    public DemarrerMaintenanceUseCase demarrerMaintenanceUseCase(MaintenanceRepository maintenanceRepo) {
        return new DemarrerMaintenanceUseCase(maintenanceRepo);
    }

    @Bean
    public TerminerMaintenanceUseCase terminerMaintenanceUseCase(MaintenanceRepository maintenanceRepo) {
        return new TerminerMaintenanceUseCase(maintenanceRepo);
    }

    @Bean
    public AnnulerMaintenanceUseCase annulerMaintenanceUseCase(MaintenanceRepository maintenanceRepo,
                                                               AuteurCourantPort auteurCourant) {
        return new AnnulerMaintenanceUseCase(maintenanceRepo, auteurCourant);
    }

    @Bean
    public DeleteMaintenanceUseCase deleteMaintenanceUseCase(MaintenanceRepository maintenanceRepo) {
        return new DeleteMaintenanceUseCase(maintenanceRepo);
    }

    @Bean
    public GetMaintenancesUseCase getMaintenancesUseCase(MaintenanceRepository maintenanceRepo) {
        return new GetMaintenancesUseCase(maintenanceRepo);
    }

    // ----- Tableau de bord -----
    @Bean
    public GetTableauBordUseCase getTableauBordUseCase(ImmeubleRepository immeubleRepo,
                                                       AppartementRepository appartementRepo,
                                                       BailRepository bailRepo,
                                                       EcheanceLoyerRepository echeanceRepo,
                                                       MaintenanceRepository maintenanceRepo) {
        return new GetTableauBordUseCase(immeubleRepo, appartementRepo, bailRepo, echeanceRepo, maintenanceRepo);
    }
}
