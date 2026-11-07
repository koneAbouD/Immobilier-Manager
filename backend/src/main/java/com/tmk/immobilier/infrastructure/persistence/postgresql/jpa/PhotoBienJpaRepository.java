package com.tmk.immobilier.infrastructure.persistence.postgresql.jpa;

import com.tmk.immobilier.infrastructure.persistence.postgresql.entities.PhotoBienEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PhotoBienJpaRepository extends JpaRepository<PhotoBienEntity, Long> {

    List<PhotoBienEntity> findByImmeubleIdOrderByIdAsc(Long immeubleId);

    long countByImmeubleId(Long immeubleId);
}
