package com.tmk.immobilier.application.ports.persistence;

import com.tmk.immobilier.application.domain.immeuble.PhotoBien;

import java.util.List;
import java.util.Optional;

public interface PhotoBienRepository {

    PhotoBien save(PhotoBien photo);

    Optional<PhotoBien> findById(Long id);

    /** Photos du bien, de la plus ancienne à la plus récente. */
    List<PhotoBien> findByImmeubleId(Long immeubleId);

    long countByImmeubleId(Long immeubleId);

    void deleteById(Long id);
}
