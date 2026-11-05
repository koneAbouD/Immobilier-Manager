package com.tmk.immobilier.infrastructure.stockage;

import com.tmk.immobilier.application.ports.document.StockageDocumentsPort;
import io.minio.BucketExistsArgs;
import io.minio.GetObjectArgs;
import io.minio.MakeBucketArgs;
import io.minio.MinioClient;
import io.minio.PutObjectArgs;
import io.minio.RemoveObjectArgs;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.stereotype.Component;

import java.io.InputStream;

/**
 * Range les documents dans un bucket MinIO. Le bucket est créé au premier
 * dépôt s'il n'existe pas, pour qu'un environnement neuf démarre sans
 * préparation manuelle.
 */
@Slf4j
@Component
@EnableConfigurationProperties(StockageProperties.class)
public class MinioStockageAdapter implements StockageDocumentsPort {

    private final MinioClient client;
    private final String bucket;
    private volatile boolean bucketVerifie;

    public MinioStockageAdapter(StockageProperties properties) {
        this.client = MinioClient.builder()
                .endpoint(properties.endpoint())
                .credentials(properties.accessKey(), properties.secretKey())
                .build();
        this.bucket = properties.bucket();
    }

    @Override
    public void deposer(String cle, InputStream contenu, long taille, String type) {
        try {
            verifierBucket();
            client.putObject(PutObjectArgs.builder()
                    .bucket(bucket).object(cle).stream(contenu, taille, -1).contentType(type).build());
        } catch (Exception e) {
            throw new StockageIndisponibleException("Le document n'a pas pu être enregistré.", e);
        }
    }

    @Override
    public InputStream lire(String cle) {
        try {
            return client.getObject(GetObjectArgs.builder().bucket(bucket).object(cle).build());
        } catch (Exception e) {
            throw new StockageIndisponibleException("Le document n'a pas pu être lu.", e);
        }
    }

    @Override
    public void supprimer(String cle) {
        try {
            client.removeObject(RemoveObjectArgs.builder().bucket(bucket).object(cle).build());
        } catch (Exception e) {
            // Un fichier orphelin ne bloque pas l'utilisateur : on le signale seulement.
            log.warn("Suppression du document {} impossible : {}", cle, e.getMessage());
        }
    }

    private void verifierBucket() throws Exception {
        if (bucketVerifie) return;
        if (!client.bucketExists(BucketExistsArgs.builder().bucket(bucket).build())) {
            client.makeBucket(MakeBucketArgs.builder().bucket(bucket).build());
            log.info("Bucket de documents « {} » créé", bucket);
        }
        bucketVerifie = true;
    }
}
