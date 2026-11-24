package com.tmk.immobilier.application.domain.organisation;

/** Organisation dans laquelle s'exécute une requête, et ce que l'appelant y peut. */
public record AccesResolu(Long utilisateurId, Long organisationId, RoleMembre role, AccesOrganisation acces,
                          String motifRestriction) {
}
