package com.tmk.immobilier.interfaces.rest.journal;

import com.tmk.immobilier.application.domain.journal.ActionJournal;
import com.tmk.immobilier.application.domain.journal.Changement;
import com.tmk.immobilier.application.domain.journal.EntreeJournal;
import com.tmk.immobilier.application.domain.journal.TypeEntite;

import java.time.LocalDateTime;
import java.util.List;

public record EntreeJournalResponse(
        Long id,
        LocalDateTime date,
        ActionJournal action,
        TypeEntite typeEntite,
        Long entiteId,
        String libelle,
        String contexte,
        String auteurNom,
        List<Changement> changements
) {
    static EntreeJournalResponse de(EntreeJournal e) {
        return new EntreeJournalResponse(e.getId(), e.getDate(), e.getAction(), e.getTypeEntite(), e.getEntiteId(),
                e.getLibelle(), e.getContexte(), e.getAuteurNom(), e.getChangements());
    }
}
