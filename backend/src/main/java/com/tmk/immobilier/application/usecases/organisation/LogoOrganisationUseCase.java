package com.tmk.immobilier.application.usecases.organisation;

import com.tmk.immobilier.application.common.DocumentFichier;
import com.tmk.immobilier.application.domain.organisation.Organisation;
import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.document.StockageDocumentsPort;
import com.tmk.immobilier.application.ports.organisation.OrganisationCourantePort;
import com.tmk.immobilier.application.ports.persistence.OrganisationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

import java.io.InputStream;
import java.util.Map;
import java.util.UUID;

/** Logo de l'organisation, imprimé en tête des contrats et des quittances. */
@RequiredArgsConstructor
public class LogoOrganisationUseCase {

    public static final long TAILLE_MAX = 2L * 1024 * 1024;

    private static final Map<String, String> EXTENSIONS = Map.of("image/jpeg", "jpg", "image/png", "png");

    private final OrganisationCourantePort organisationCourante;
    private final OrganisationRepository organisationRepository;
    private final StockageDocumentsPort stockage;

    @Transactional
    public Organisation deposer(String type, long taille, InputStream contenu) {
        String extension = type != null ? EXTENSIONS.get(type.toLowerCase()) : null;
        if (extension == null) {
            throw new RegleMetierException("FORMAT_LOGO_INVALIDE", "Le logo doit être une image JPEG ou PNG.");
        }
        if (taille <= 0 || taille > TAILLE_MAX) {
            throw new RegleMetierException("TAILLE_LOGO_INVALIDE", "Le logo doit peser moins de 2 Mo.");
        }
        Organisation organisation = courante();
        String ancienne = organisation.getLogoCle();
        String cle = "organisations/" + organisation.getId() + "/logo-" + UUID.randomUUID() + "." + extension;
        stockage.deposer(cle, contenu, taille, type);
        organisation.setLogoCle(cle);
        organisation.setLogoType(type);
        Organisation saved = organisationRepository.save(organisation);
        if (ancienne != null) stockage.supprimer(ancienne);
        return saved;
    }

    @Transactional(readOnly = true)
    public DocumentFichier lire() {
        Organisation organisation = courante();
        if (organisation.getLogoCle() == null) throw new ResourceNotFoundException("Aucun logo n'a été chargé.");
        String extension = organisation.getLogoCle().substring(organisation.getLogoCle().lastIndexOf('.') + 1);
        return new DocumentFichier("logo." + extension, organisation.getLogoType(), -1,
                stockage.lire(organisation.getLogoCle()));
    }

    @Transactional
    public void supprimer() {
        Organisation organisation = courante();
        String cle = organisation.getLogoCle();
        if (cle == null) return;
        organisation.setLogoCle(null);
        organisation.setLogoType(null);
        organisationRepository.save(organisation);
        stockage.supprimer(cle);
    }

    private Organisation courante() {
        Long id = organisationCourante.id();
        return organisationRepository.findById(id).orElseThrow(() -> ResourceNotFoundException.of("Organisation", id));
    }
}
