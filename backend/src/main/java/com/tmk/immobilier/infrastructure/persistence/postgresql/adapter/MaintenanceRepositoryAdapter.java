package com.tmk.immobilier.infrastructure.persistence.postgresql.adapter;

import com.tmk.immobilier.application.common.PageResult;
import com.tmk.immobilier.application.domain.maintenance.Maintenance;
import com.tmk.immobilier.application.domain.maintenance.PrioriteMaintenance;
import com.tmk.immobilier.application.domain.maintenance.StatutMaintenance;
import com.tmk.immobilier.application.ports.persistence.MaintenanceRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.jpa.MaintenanceJpaRepository;
import com.tmk.immobilier.infrastructure.persistence.postgresql.jpa.MaintenanceSpecs;
import com.tmk.immobilier.infrastructure.persistence.postgresql.mapper.MaintenancePersistenceMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.Optional;

@Component
@RequiredArgsConstructor
public class MaintenanceRepositoryAdapter implements MaintenanceRepository {

    private static final Sort TRI = Sort.by(Sort.Order.desc("dateSignalement"), Sort.Order.desc("id"));

    private final MaintenanceJpaRepository jpaRepository;
    private final MaintenancePersistenceMapper mapper;

    @Override
    public Maintenance save(Maintenance maintenance) {
        return mapper.toDomain(jpaRepository.save(mapper.toEntity(maintenance)));
    }

    @Override
    public Optional<Maintenance> findById(Long id) {
        return jpaRepository.findById(id).map(mapper::toDomain);
    }

    @Override
    public PageResult<Maintenance> findPage(Long immeubleId, Long appartementId, StatutMaintenance statut,
                                            PrioriteMaintenance priorite, String recherche, int page, int size) {
        return PageResults.of(jpaRepository.findAll(
                MaintenanceSpecs.byFiltres(immeubleId, appartementId, statut, priorite, recherche),
                PageRequest.of(page, size, TRI)), mapper::toDomain);
    }

    @Override
    public boolean existsByImmeubleId(Long immeubleId) {
        return jpaRepository.existsByImmeubleId(immeubleId);
    }

    @Override
    public boolean existsByAppartementId(Long appartementId) {
        return jpaRepository.existsByAppartementId(appartementId);
    }

    @Override
    public long countByStatutIn(Collection<StatutMaintenance> statuts) {
        return jpaRepository.countByStatutIn(statuts);
    }

    @Override
    public long countByStatutInAndPriorite(Collection<StatutMaintenance> statuts, PrioriteMaintenance priorite) {
        return jpaRepository.countByStatutInAndPriorite(statuts, priorite);
    }

    @Override
    public void deleteById(Long id) {
        jpaRepository.deleteById(id);
    }
}
