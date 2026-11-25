package com.tmk.immobilier.infrastructure.persistence.postgresql.adapter;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.journal.ActionJournal;
import com.tmk.immobilier.application.domain.journal.EntreeJournal;
import com.tmk.immobilier.application.domain.journal.TypeEntite;
import com.tmk.immobilier.application.ports.persistence.JournalActionsRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.JournalActionEntity;
import com.tmk.immobilier.infrastructure.persistence.postgresql.jpa.JournalActionJpaRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.jpa.JournalActionSpecs;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

@Component
@RequiredArgsConstructor
public class JournalActionsRepositoryAdapter implements JournalActionsRepository {

    /** Plus récentes d'abord ; l'identifiant départage deux actions de la même seconde. */
    private static final Sort TRI = Sort.by(Sort.Order.desc("dateAction"), Sort.Order.desc("id"));

    private final JournalActionJpaRepository jpaRepository;

    @Override
    public EntreeJournal save(EntreeJournal e) {
        return toDomain(jpaRepository.save(JournalActionEntity.builder()
                .dateAction(e.getDate())
                .action(e.getAction())
                .typeEntite(e.getTypeEntite())
                .entiteId(e.getEntiteId())
                .libelle(tronquer(e.getLibelle()))
                .contexte(tronquer(e.getContexte()))
                .auteurId(e.getAuteurId())
                .auteurNom(tronquer(e.getAuteurNom()))
                .changements(e.getChangements() == null ? new ArrayList<>() : new ArrayList<>(e.getChangements()))
                .build()));
    }

    @Override
    public PageResult<EntreeJournal> findPage(TypeEntite type, ActionJournal action, String recherche,
                                              int page, int size) {
        return PageResults.of(jpaRepository.findAll(JournalActionSpecs.filtre(type, action, recherche),
                PageRequest.of(page, size, TRI)), JournalActionsRepositoryAdapter::toDomain);
    }

    private static EntreeJournal toDomain(JournalActionEntity e) {
        return EntreeJournal.builder()
                .id(e.getId())
                .date(e.getDateAction())
                .action(e.getAction())
                .typeEntite(e.getTypeEntite())
                .entiteId(e.getEntiteId())
                .libelle(e.getLibelle())
                .contexte(e.getContexte())
                .auteurId(e.getAuteurId())
                .auteurNom(e.getAuteurNom())
                .changements(e.getChangements() == null ? List.of() : List.copyOf(e.getChangements()))
                .build();
    }

    private static String tronquer(String texte) {
        return texte == null || texte.length() <= 255 ? texte : texte.substring(0, 254) + "…";
    }
}
