package com.tmk.immobilier.infrastructure.persistence.postgresql.jpa;

import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.JournalActionEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

@Repository
public interface JournalActionJpaRepository extends JpaRepository<JournalActionEntity, Long>,
        JpaSpecificationExecutor<JournalActionEntity> {
}
