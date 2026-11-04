package com.tmk.immobilier.application.usecases.bail;

import com.tmk.immobilier.application.domain.bail.Bail;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.application.ports.persistence.BailRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;

@RequiredArgsConstructor
public class GetBailByIdUseCase {

    private final BailRepository bailRepository;

    @Transactional(readOnly = true)
    public Bail execute(Long id) {
        return bailRepository.findById(id).orElseThrow(() -> ResourceNotFoundException.of("Bail", id));
    }
}
