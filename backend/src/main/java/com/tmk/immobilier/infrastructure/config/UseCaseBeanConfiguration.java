package com.tmk.immobilier.infrastructure.config;

import com.tmk.immobilier.application.ports.auth.KeycloakAuthPort;
import com.tmk.immobilier.application.ports.document.ContratBailGenerateurPort;
import com.tmk.immobilier.application.ports.document.StockageDocumentsPort;
import com.tmk.immobilier.application.ports.persistence.AppartementRepository;
import com.tmk.immobilier.application.ports.persistence.BailRepository;
import com.tmk.immobilier.application.ports.persistence.EcheanceLoyerRepository;
import com.tmk.immobilier.application.ports.persistence.ImmeubleRepository;
import com.tmk.immobilier.application.ports.persistence.LocataireRepository;
import com.tmk.immobilier.application.ports.persistence.MaintenanceRepository;
import com.tmk.immobilier.application.ports.persistence.PaiementLoyerRepository;
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

    // ----- Immeubles -----
    @Bean
    public CreateImmeubleUseCase createImmeubleUseCase(ImmeubleRepository immeubleRepo) {
        return new CreateImmeubleUseCase(immeubleRepo);
    }

    @Bean
    public UpdateImmeubleUseCase updateImmeubleUseCase(ImmeubleRepository immeubleRepo) {
        return new UpdateImmeubleUseCase(immeubleRepo);
    }

    @Bean
    public DeleteImmeubleUseCase deleteImmeubleUseCase(ImmeubleRepository immeubleRepo,
                                                       AppartementRepository appartementRepo,
                                                       MaintenanceRepository maintenanceRepo) {
        return new DeleteImmeubleUseCase(immeubleRepo, appartementRepo, maintenanceRepo);
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
                                                             ImmeubleRepository immeubleRepo) {
        return new CreateAppartementUseCase(appartementRepo, immeubleRepo);
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
                                                                   AuteurCourantPort auteurCourant) {
        return new DeposerPieceIdentiteUseCase(locataireRepo, stockage, auteurCourant);
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

    // ----- Baux -----
    @Bean
    public CreateBailUseCase createBailUseCase(BailRepository bailRepo,
                                               AppartementRepository appartementRepo,
                                               LocataireRepository locataireRepo,
                                               GenererEcheancesUseCase genererEcheancesUseCase) {
        return new CreateBailUseCase(bailRepo, appartementRepo, locataireRepo, genererEcheancesUseCase);
    }

    @Bean
    public UpdateBailUseCase updateBailUseCase(BailRepository bailRepo) {
        return new UpdateBailUseCase(bailRepo);
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
                                                               ContratBailGenerateurPort generateur) {
        return new GenererContratBailUseCase(bailRepo, generateur);
    }

    @Bean
    public DeposerContratSigneUseCase deposerContratSigneUseCase(BailRepository bailRepo,
                                                                 StockageDocumentsPort stockage,
                                                                 AuteurCourantPort auteurCourant) {
        return new DeposerContratSigneUseCase(bailRepo, stockage, auteurCourant);
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
