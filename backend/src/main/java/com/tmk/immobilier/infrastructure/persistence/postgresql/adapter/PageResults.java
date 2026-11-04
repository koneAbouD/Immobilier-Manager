package com.tmk.immobilier.infrastructure.persistence.postgresql.adapter;

import com.tmk.immobilier.application.common.PageResult;
import org.springframework.data.domain.Page;

import java.util.function.Function;

/** Conversion d'une page Spring Data en {@link PageResult} applicatif. */
final class PageResults {

    private PageResults() {
    }

    static <E, D> PageResult<D> of(Page<E> page, Function<E, D> mapper) {
        return new PageResult<>(page.getContent().stream().map(mapper).toList(),
                page.getNumber(), page.getSize(), page.getTotalElements());
    }
}
