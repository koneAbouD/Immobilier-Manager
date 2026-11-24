package com.tmk.immobilier.interfaces.rest.organisation.dto;

import com.tmk.immobilier.application.domain.organisation.RoleMembre;

/** Champs nuls laissés inchangés. */
public record ModificationMembreRequest(RoleMembre role, Boolean actif) {
}
