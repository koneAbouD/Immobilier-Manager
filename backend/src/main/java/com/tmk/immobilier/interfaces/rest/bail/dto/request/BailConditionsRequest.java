package com.tmk.immobilier.interfaces.rest.bail.dto.request;

import com.tmk.immobilier.application.domain.bail.UsageBail;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDate;

/** Révision des conditions d'un bail actif ; le logement et le locataire ne changent pas. */
public record BailConditionsRequest(
        /** Changement de régime du bail (habitation / professionnel). Nul : inchangé. */
        UsageBail usage,
        LocalDate dateDebut,
        LocalDate dateFin,
        @Positive(message = "Le loyer mensuel doit être strictement positif.") BigDecimal loyerMensuel,
        @PositiveOrZero(message = "Les charges ne peuvent pas être négatives.") BigDecimal charges,
        @PositiveOrZero(message = "Le dépôt de garantie ne peut pas être négatif.") BigDecimal depotGarantie,
        /** Si renseigné, le dépôt de garantie vaut ce nombre de mois × le loyer mensuel. */
        @Min(value = 0, message = "Le nombre de mois de caution doit être compris entre 0 et 24.")
        @Max(value = 24, message = "Le nombre de mois de caution doit être compris entre 0 et 24.")
        Integer moisCaution,
        /** Mois de loyer réglés à la signature : ils ne sont pas facturés. */
        @Min(value = 0, message = "Le nombre de mois d'avance doit être compris entre 0 et 24.")
        @Max(value = 24, message = "Le nombre de mois d'avance doit être compris entre 0 et 24.")
        Integer moisAvance,
        /** Facultatif : à défaut, calculé (mois suivant la création, après l'avance). Seul le mois compte. */
        LocalDate premierMoisFacture,
        @Min(value = 1, message = "Le jour d'échéance doit être compris entre 1 et 28.")
        @Max(value = 28, message = "Le jour d'échéance doit être compris entre 1 et 28.")
        Integer jourEcheance,
        /** Changement de recouvrement : possible dans les 45 jours suivant la création. Nul : inchangé. */
        Boolean externe,
        @Size(max = 150, message = "Le nom du gestionnaire externe ne doit pas dépasser 150 caractères.")
        String gestionnaireExterne
) {
}
