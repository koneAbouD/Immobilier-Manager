package com.tmk.immobilier.application.ports.persistence;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.journal.ActionJournal;
import com.tmk.immobilier.application.domain.journal.EntreeJournal;
import com.tmk.immobilier.application.domain.journal.TypeEntite;

/** Journal des modifications et suppressions de l'organisation courante. */
public interface JournalActionsRepository {

    EntreeJournal save(EntreeJournal entree);

    /** Entrées les plus récentes d'abord ; chaque filtre nul est ignoré. */
    PageResult<EntreeJournal> findPage(TypeEntite type, ActionJournal action, String recherche, int page, int size);
}
