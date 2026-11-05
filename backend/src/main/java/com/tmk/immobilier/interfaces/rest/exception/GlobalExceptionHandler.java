package com.tmk.immobilier.interfaces.rest.exception;

import com.tmk.immobilier.application.exception.AuthServiceUnavailableException;
import com.tmk.immobilier.application.exception.AuthenticationFailedException;
import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.exception.ResourceAlreadyExistsException;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.infrastructure.stockage.StockageIndisponibleException;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.ErrorResponse;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.multipart.MaxUploadSizeExceededException;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    // ── Messages lisibles par contrainte DB ────────────────────────────────
    // Dernier filet : les use cases vérifient ces règles avant d'écrire, mais
    // deux requêtes concurrentes peuvent passer les contrôles ensemble.
    private static final Map<String, String> CONSTRAINT_MESSAGES = Map.of(
            "immeubles_nom_key", "Un immeuble porte déjà ce nom.",
            "uk_appartements_immeuble_reference", "Cette référence est déjà utilisée dans cet immeuble.",
            "uk_locataires_telephone", "Un locataire avec ce numéro de téléphone existe déjà.",
            "uk_baux_appartement_actif", "Ce logement a déjà un bail actif.",
            "uk_echeances_bail_periode", "Le loyer de ce mois a déjà été émis pour ce bail.",
            "chk_paiements_montant_positif", "Le montant du paiement doit être strictement positif.",
            "chk_baux_jour_echeance", "Le jour d'échéance doit être compris entre 1 et 28."
    );

    // Formats PostgreSQL : constraint "name" et H2 : constraint [name]
    private static final Pattern CONSTRAINT_PATTERN =
            Pattern.compile("constraint [\"\\[]([\\w]+)[\"\\]]", Pattern.CASE_INSENSITIVE);

    // ── Fabrique de réponse + journalisation centralisée ───────────────────
    //   • 5xx (inattendues) → ERROR + stacktrace pour diagnostic.
    //   • 4xx (métier/client attendues) → WARN concis, sans stacktrace.

    private ResponseEntity<ApiError> respond(HttpStatus status, String code, String message,
                                             HttpServletRequest request, List<String> details, Exception ex) {
        String req = request.getMethod() + " " + request.getRequestURI();
        String suffixe = (details == null || details.isEmpty()) ? "" : " " + details;
        if (status.is5xxServerError()) {
            log.error("[{}] {} ({}) -> {} : {}{}", req, ex.getClass().getSimpleName(), code,
                    status.value(), message, suffixe, ex);
        } else {
            log.warn("[{}] {} ({}) -> {} : {}{}", req, ex.getClass().getSimpleName(), code,
                    status.value(), message, suffixe);
        }
        return ResponseEntity.status(status).body(ApiError.builder()
                .status(status.value())
                .error(code)
                .message(message)
                .path(request.getRequestURI())
                .timestamp(LocalDateTime.now())
                .details(details)
                .build());
    }

    private ResponseEntity<ApiError> respond(HttpStatus status, String code, String message,
                                             HttpServletRequest request, Exception ex) {
        return respond(status, code, message, request, null, ex);
    }

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ApiError> handleNotFound(ResourceNotFoundException ex, HttpServletRequest request) {
        return respond(HttpStatus.NOT_FOUND, "NOT_FOUND", ex.getMessage(), request, ex);
    }

    @ExceptionHandler(ResourceAlreadyExistsException.class)
    public ResponseEntity<ApiError> handleAlreadyExists(ResourceAlreadyExistsException ex, HttpServletRequest request) {
        return respond(HttpStatus.CONFLICT, "ALREADY_EXISTS", ex.getMessage(), request, ex);
    }

    @ExceptionHandler(RegleMetierException.class)
    public ResponseEntity<ApiError> handleRegleMetier(RegleMetierException ex, HttpServletRequest request) {
        return respond(HttpStatus.CONFLICT, ex.getCode(), ex.getMessage(), request, ex);
    }

    @ExceptionHandler(AuthenticationFailedException.class)
    public ResponseEntity<ApiError> handleAuthFailed(AuthenticationFailedException ex, HttpServletRequest request) {
        return respond(HttpStatus.UNAUTHORIZED, "AUTHENTICATION_FAILED", ex.getMessage(), request, ex);
    }

    @ExceptionHandler(AuthServiceUnavailableException.class)
    public ResponseEntity<ApiError> handleAuthUnavailable(AuthServiceUnavailableException ex,
                                                          HttpServletRequest request) {
        return respond(HttpStatus.SERVICE_UNAVAILABLE, "AUTH_SERVICE_UNAVAILABLE",
                "Le service d'authentification est momentanément indisponible. Réessayez dans un instant.",
                request, ex);
    }

    @ExceptionHandler(StockageIndisponibleException.class)
    public ResponseEntity<ApiError> handleStockage(StockageIndisponibleException ex, HttpServletRequest request) {
        return respond(HttpStatus.SERVICE_UNAVAILABLE, "STOCKAGE_INDISPONIBLE",
                ex.getMessage() + " Le stockage des documents ne répond pas, réessayez dans un instant.",
                request, ex);
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiError> handleAccessDenied(AccessDeniedException ex, HttpServletRequest request) {
        return respond(HttpStatus.FORBIDDEN, "ACCESS_DENIED",
                "Vous n'avez pas les droits nécessaires pour cette action.", request, ex);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiError> handleValidation(MethodArgumentNotValidException ex, HttpServletRequest request) {
        List<String> details = ex.getBindingResult().getFieldErrors().stream()
                .map(e -> e.getField() + " : " + e.getDefaultMessage())
                .toList();
        String message = ex.getBindingResult().getFieldErrors().stream()
                .findFirst()
                .map(e -> e.getDefaultMessage())
                .orElse("Données invalides.");
        return respond(HttpStatus.BAD_REQUEST, "VALIDATION_FAILED", message, request, details, ex);
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiError> handleNotReadable(HttpMessageNotReadableException ex, HttpServletRequest request) {
        return respond(HttpStatus.BAD_REQUEST, "MALFORMED_REQUEST",
                "Requête illisible : vérifiez le format des champs (dates AAAA-MM-JJ, valeurs autorisées).",
                request, ex);
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ApiError> handleTypeMismatch(MethodArgumentTypeMismatchException ex,
                                                       HttpServletRequest request) {
        return respond(HttpStatus.BAD_REQUEST, "INVALID_PARAMETER",
                "Valeur invalide pour le paramètre « " + ex.getName() + " ».", request, ex);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiError> handleIllegalArgument(IllegalArgumentException ex, HttpServletRequest request) {
        return respond(HttpStatus.BAD_REQUEST, "BAD_REQUEST", ex.getMessage(), request, ex);
    }

    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<ApiError> handleMaxUpload(MaxUploadSizeExceededException ex, HttpServletRequest request) {
        return respond(HttpStatus.PAYLOAD_TOO_LARGE, "FILE_TOO_LARGE",
                "Le fichier est trop volumineux.", request, ex);
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ApiError> handleDataIntegrity(DataIntegrityViolationException ex,
                                                        HttpServletRequest request) {
        String cause = ex.getMostSpecificCause().getMessage();
        Matcher matcher = CONSTRAINT_PATTERN.matcher(cause != null ? cause : "");
        String message = matcher.find()
                ? CONSTRAINT_MESSAGES.getOrDefault(matcher.group(1),
                "Opération refusée : elle violerait une règle d'intégrité des données.")
                : "Opération refusée : elle violerait une règle d'intégrité des données.";
        return respond(HttpStatus.CONFLICT, "DATA_INTEGRITY", message, request, ex);
    }

    /**
     * Erreurs du cadre web (route inconnue, verbe non supporté, paramètre
     * manquant…) : elles portent déjà leur statut HTTP, qu'on conserve au lieu
     * de les transformer en 500.
     */
    @ExceptionHandler({
            org.springframework.web.servlet.resource.NoResourceFoundException.class,
            org.springframework.web.HttpRequestMethodNotSupportedException.class,
            org.springframework.web.HttpMediaTypeNotSupportedException.class,
            org.springframework.web.bind.MissingServletRequestParameterException.class
    })
    public ResponseEntity<ApiError> handleFramework(Exception ex, HttpServletRequest request) {
        HttpStatus status = HttpStatus.valueOf(((ErrorResponse) ex).getStatusCode().value());
        return respond(status, status.name(), ex.getMessage(), request, ex);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiError> handleUnexpected(Exception ex, HttpServletRequest request) {
        return respond(HttpStatus.INTERNAL_SERVER_ERROR, "INTERNAL_ERROR",
                "Une erreur inattendue s'est produite. Réessayez ou contactez le support.", request, ex);
    }
}
