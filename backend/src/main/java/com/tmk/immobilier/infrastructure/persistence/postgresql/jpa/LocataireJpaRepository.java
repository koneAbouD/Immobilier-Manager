package com.tmk.immobilier.infrastructure.persistence.postgresql.jpa;

import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.LocataireEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

@Repository
public interface LocataireJpaRepository extends JpaRepository<LocataireEntity, Long>,
        JpaSpecificationExecutor<LocataireEntity> {

    boolean existsByTelephone(String telephone);

    boolean existsByTelephoneAndIdNot(String telephone, Long id);
}
