package com.tmk.immobilier.infrastructure.config.security;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Freine les inscriptions en rafale depuis une même adresse (fenêtre glissante
 * d'une heure, en mémoire). Suffisant pour une instance ; derrière plusieurs
 * instances, déporter ce compteur (Redis, passerelle API).
 */
@Component
public class LimiteurInscriptions {

    private static final Duration FENETRE = Duration.ofHours(1);

    private final int maximum;
    private final Map<String, Deque<Instant>> tentatives = new ConcurrentHashMap<>();

    public LimiteurInscriptions(@Value("${app.inscription.max-par-heure:5}") int maximum) {
        this.maximum = maximum;
    }

    /** @return faux si l'adresse a épuisé son quota pour l'heure écoulée */
    public boolean autoriser(String adresse) {
        Instant maintenant = Instant.now();
        Instant limite = maintenant.minus(FENETRE);
        if (tentatives.size() > 10_000) tentatives.values().removeIf(d -> d.isEmpty() || d.peekLast().isBefore(limite));
        Deque<Instant> historique = tentatives.computeIfAbsent(adresse, a -> new ArrayDeque<>());
        synchronized (historique) {
            while (!historique.isEmpty() && historique.peekFirst().isBefore(limite)) historique.pollFirst();
            if (historique.size() >= maximum) return false;
            historique.addLast(maintenant);
            return true;
        }
    }
}
