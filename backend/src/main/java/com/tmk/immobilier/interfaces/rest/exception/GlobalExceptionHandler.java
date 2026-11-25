package com.tmk.immobilier.interfaces.rest.exception;

import com.tmk.immobilier.application.exception.AccesOrganisationException;
import com.tmk.immobilier.application.exception.AuthServiceUnavailableException;
import com.tmk.immobilier.application.exception.LimiteAbonnementException;
import com.tmk.immobilier.application.exception.AuthenticationFailedException;
import com.tmk.immobilier.application.exception.RegleMetierException;
import com.tmk.immobilier.application.exception.ResourceAlreadyExistsException;
import com.tmk.immobilier.application.exception.ResourceNotFoundException;
import com.tmk.immobilier.infrastructure.stockage.StockageIndisponibleException;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.NestedExceptionUtils;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.dao.OptimisticLockingFailureException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.ErrorResponse;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.HandlerMethodValidationException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.multipart.support.MissingServletRequestPartException;

import java.sql.SQLException;
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
    private static final Map<String, String> CONSTRAINT_MESSAGES = Map.ofEntries(
            Map.entry("uk_immeubles_organisation_nom", "Un bien porte déjà ce nom."),
            Map.entry("uk_appartements_immeuble_reference", "Cette référence est déjà utilisée dans cet immeuble."),
            Map.entry("uk_locataires_organisation_telephone", "Un locataire avec ce numéro de téléphone existe déjà."),
            Map.entry("uk_baux_appartement_actif", "Ce logement a déjà un bail actif."),
            Map.entry("uk_baux_organisation_reference", "Cette référence de bail est déjà utilisée."),
            Map.entry("uk_echeances_bail_periode", "Le loyer de ce mois a déjà été émis pour ce bail."),
            Map.entry("chk_paiements_montant_positif", "Le montant du paiement doit être strictement positif."),
            Map.entry("chk_baux_jour_echeance", "Le jour d'échéance doit être compris entre 1 et 28."),
            Map.entry("uk_utilisateurs_email", "Un compte existe déjà avec cette adresse e-mail."),
            Map.entry("uk_utilisateurs_telephone", "Un compte existe déjà avec ce numéro de téléphone."),
            Map.entry("uk_membres_organisation_utilisateur", "Cette personne fait déjà partie de l'équipe."),
            Map.entry("uk_membres_proprietaire", "L'organisation a déjà un propriétaire.")
    );

    // Formats PostgreSQL : constraint "name" et H2 : constraint [name]
    private static final Pattern CONSTRAINT_PATTERN =
            Pattern.compile("constraint [\"\\[]([\\w]+)[\"\\]]", Pattern.CASE_INSENSITIVE);

    // Colonne d'un NOT NULL PostgreSQL : null value in column "loyer" of relation "baux"
    private static final Pattern NOT_NULL_COLUMN_PATTERN =
            Pattern.compile("column [\"\\[]([\\w]+)[\"\\]]", Pattern.CASE_INSENSITIVE);

    private static final String MESSAGE_INTEGRITE =
            "Opération refusée : elle violerait une règle d'intégrité des données.";

    /** Taille max d'un fichier, telle que configurée (ex. « 8MB »), citée dans le message. */
    @Value("${spring.servlet.multipart.max-file-size:8MB}")
    private String maxFileSize = "8MB";

    // ── Fabrique de réponse + journalisation centralisée ───────────────────
    //   • 5xx (inattendues) → ERROR + stacktrace pour diagnostic.
    //   • 4xx (métier/client attendues) → WARN concis, sans stacktrace. Quand
    //     le client reçoit un message neutre, la cause technique est ajoutée
    //     au log : sinon un « Requête invalide » en prod ne dit rien.

    private ResponseEntity<ApiError> respond(HttpStatus status, String code, String message,
                                             HttpServletRequest request, List<String> details, Exception ex) {
        String req = request.getMethod() + " " + request.getRequestURI();
        String suffixe = (details == null || details.isEmpty()) ? "" : " " + details;
        if (status.is5xxServerError()) {
            log.error("[{}] {} ({}) -> {} : {}{}", req, ex.getClass().getSimpleName(), code,
                    status.value(), message, suffixe, ex);
        } else {
            String technique = NestedExceptionUtils.getMostSpecificCause(ex).getMessage();
            String cause = technique != null && !technique.equals(message)
                    ? " | cause : " + technique : "";
            log.warn("[{}] {} ({}) -> {} : {}{}{}", req, ex.getClass().getSimpleName(), code,
                    status.value(), message, suffixe, cause);
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

    @ExceptionHandler(LimiteAbonnementException.class)
    public ResponseEntity<ApiError> handleLimite(LimiteAbonnementException ex, HttpServletRequest request) {
        return respond(HttpStatus.PAYMENT_REQUIRED, ex.getCode(), ex.getMessage(), request, ex);
    }

    @ExceptionHandler(AccesOrganisationException.class)
    public ResponseEntity<ApiError> handleAccesOrganisation(AccesOrganisationException ex, HttpServletRequest request) {
        HttpStatus status = ex.getMotif() == AccesOrganisationException.Motif.LECTURE_SEULE
                ? HttpStatus.PAYMENT_REQUIRED : HttpStatus.FORBIDDEN;
        return respond(status, ex.getMotif().name(), ex.getMessage(), request, ex);
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
        // Tous les refus d'un coup, pas seulement le premier : l'utilisateur
        // corrige son formulaire en une fois au lieu de le renvoyer en boucle.
        List<String> messages = ex.getBindingResult().getAllErrors().stream()
                .map(e -> e.getDefaultMessage())
                .filter(m -> m != null && !m.isBlank())
                .distinct()
                .toList();
        String message = messages.isEmpty() ? "Données invalides." : String.join("\n", messages);
        return respond(HttpStatus.BAD_REQUEST, "VALIDATION_FAILED", message, request, details, ex);
    }

    @ExceptionHandler(HandlerMethodValidationException.class)
    public ResponseEntity<ApiError> handleMethodValidation(HandlerMethodValidationException ex,
                                                           HttpServletRequest request) {
        List<String> messages = ex.getAllErrors().stream()
                .map(e -> e.getDefaultMessage())
                .filter(m -> m != null && !m.isBlank())
                .distinct()
                .toList();
        String message = messages.isEmpty() ? "Paramètres invalides." : String.join("\n", messages);
        return respond(HttpStatus.BAD_REQUEST, "VALIDATION_FAILED", message, request, ex);
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

    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<ApiError> handleMissingParameter(MissingServletRequestParameterException ex,
                                                           HttpServletRequest request) {
        return respond(HttpStatus.BAD_REQUEST, "MISSING_PARAMETER",
                "Paramètre obligatoire manquant : « " + ex.getParameterName() + " ».", request, ex);
    }

    @ExceptionHandler(MissingServletRequestPartException.class)
    public ResponseEntity<ApiError> handleMissingPart(MissingServletRequestPartException ex,
                                                      HttpServletRequest request) {
        return respond(HttpStatus.BAD_REQUEST, "MISSING_FILE",
                "Aucun fichier reçu : choisissez un document puis réessayez.", request, ex);
    }

    /**
     * Le code applicatif ne lève pas d'{@code IllegalArgumentException} (les
     * refus passent par {@link RegleMetierException}) : celles qui arrivent ici
     * viennent d'une bibliothèque (énumération inconnue, UUID mal formé…) et
     * leur texte, en anglais technique, n'est pas montré au client.
     */
    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiError> handleIllegalArgument(IllegalArgumentException ex, HttpServletRequest request) {
        return respond(HttpStatus.BAD_REQUEST, "BAD_REQUEST",
                "Requête invalide : une des valeurs envoyées n'est pas acceptée.", request, ex);
    }

    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<ApiError> handleMaxUpload(MaxUploadSizeExceededException ex, HttpServletRequest request) {
        return respond(HttpStatus.PAYLOAD_TOO_LARGE, "FILE_TOO_LARGE",
                "Le fichier est trop volumineux : la taille maximale est de " + maxFileSize
                        + ". Choisissez un fichier plus léger ou réduisez la qualité de la photo.",
                request, List.of("tailleMax:" + maxFileSize), ex);
    }

    /**
     * Dernier filet des contraintes PostgreSQL, distinguées par SQLState pour
     * ne pas annoncer un « doublon » quand c'est une référence ou une valeur
     * interdite :
     * <ul>
     *   <li>23505 UNIQUE → 409, message de {@link #CONSTRAINT_MESSAGES} ;</li>
     *   <li>23503 FOREIGN KEY → 409 {@code REFERENCE_EXISTANTE} (suppression
     *       d'un élément encore utilisé) ;</li>
     *   <li>23514 CHECK → 422 {@code VALEUR_NON_AUTORISEE} ;</li>
     *   <li>23502 NOT NULL → 400 {@code CHAMP_OBLIGATOIRE}.</li>
     * </ul>
     * Le nom de la contrainte part en {@code details} pour le diagnostic.
     */
    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ApiError> handleDataIntegrity(DataIntegrityViolationException ex,
                                                        HttpServletRequest request) {
        Throwable racine = ex.getMostSpecificCause();
        String sqlState = racine instanceof SQLException sql && sql.getSQLState() != null
                ? sql.getSQLState() : "";
        String brut = racine.getMessage() != null ? racine.getMessage() : "";

        if ("23502".equals(sqlState)) {
            Matcher col = NOT_NULL_COLUMN_PATTERN.matcher(brut);
            String colonne = col.find() ? col.group(1) : null;
            return respond(HttpStatus.BAD_REQUEST, "CHAMP_OBLIGATOIRE",
                    "Données incomplètes : un champ obligatoire est manquant.", request,
                    colonne != null ? List.of("colonne:" + colonne) : null, ex);
        }

        Matcher m = CONSTRAINT_PATTERN.matcher(brut);
        String contrainte = m.find() ? m.group(1) : null;
        List<String> details = contrainte != null ? List.of("contrainte:" + contrainte) : null;
        String message = contrainte != null ? CONSTRAINT_MESSAGES.get(contrainte) : null;

        return switch (sqlState) {
            case "23503" -> respond(HttpStatus.CONFLICT, "REFERENCE_EXISTANTE",
                    message != null ? message
                            : "Opération impossible : cet élément est encore utilisé ailleurs "
                              + "(bail, paiement, document…). Retirez d'abord ce qui s'y rattache.",
                    request, details, ex);
            case "23514" -> respond(HttpStatus.UNPROCESSABLE_ENTITY, "VALEUR_NON_AUTORISEE",
                    message != null ? message : "Une des valeurs saisies n'est pas autorisée.",
                    request, details, ex);
            default -> respond(HttpStatus.CONFLICT, "DATA_INTEGRITY",
                    message != null ? message : MESSAGE_INTEGRITE, request, details, ex);
        };
    }

    /**
     * Deux enregistrements simultanés de la même fiche : le second part d'une
     * version périmée.
     */
    @ExceptionHandler(OptimisticLockingFailureException.class)
    public ResponseEntity<ApiError> handleOptimisticLock(OptimisticLockingFailureException ex,
                                                         HttpServletRequest request) {
        return respond(HttpStatus.CONFLICT, "FICHE_MODIFIEE",
                "Cette fiche vient d'être modifiée par quelqu'un d'autre. Rechargez-la puis réessayez.",
                request, ex);
    }

    /**
     * Filet de sécurité. Les exceptions natives de Spring MVC (route inconnue,
     * verbe non supporté, type de contenu refusé…) portent déjà leur statut
     * 4xx : on le conserve, avec un message en français plutôt que le texte
     * technique anglais du cadre. Tout le reste est une 500 dont le détail est
     * journalisé mais jamais exposé.
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiError> handleUnexpected(Exception ex, HttpServletRequest request) {
        if (ex instanceof ErrorResponse er) {
            HttpStatus status = HttpStatus.resolve(er.getStatusCode().value());
            if (status != null && status.is4xxClientError()) {
                return respond(status, status.name(), messageClient(status), request, ex);
            }
        }
        return respond(HttpStatus.INTERNAL_SERVER_ERROR, "INTERNAL_ERROR",
                "Une erreur inattendue s'est produite. Réessayez ou contactez le support.", request, ex);
    }

    static String messageClient(HttpStatus status) {
        return switch (status) {
            case NOT_FOUND -> "Ressource introuvable.";
            case METHOD_NOT_ALLOWED -> "Opération non autorisée sur cette ressource.";
            case UNSUPPORTED_MEDIA_TYPE -> "Format de contenu non pris en charge.";
            case NOT_ACCEPTABLE -> "Format de réponse demandé non disponible.";
            default -> "Requête invalide.";
        };
    }
}
