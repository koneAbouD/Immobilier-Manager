package com.tmk.immobilier.interfaces.rest.exception;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@AllArgsConstructor
public class ApiError {
    private int status;
    /** Code stable exploitable par le client (ex. APPARTEMENT_DEJA_LOUE). */
    private String error;
    /** Message lisible, présentable tel quel à l'utilisateur. */
    private String message;
    private String path;
    private LocalDateTime timestamp;
    private List<String> details;
}
