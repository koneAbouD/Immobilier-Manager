package com.tmk.immobilier_manager

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.core.content.FileProvider
import java.io.File

/**
 * Partage d'un document PDF (quittance), message en légende, quand le
 * locataire n'a pas de numéro : le contact est de toute façon à choisir dans
 * WhatsApp, autant que le document y arrive déjà joint.
 *
 * Avec un numéro, l'application ne passe pas par ici : elle enregistre le PDF
 * et ouvre la conversation par le lien wa.me, seul chemin qui mène sûrement au
 * bon locataire — WhatsApp ignore tout destinataire joint à une intention
 * ACTION_SEND.
 *
 * Sans WhatsApp ni WhatsApp Business, la feuille de partage d'Android prend le
 * relais. (Repris de VTC Manager.)
 */
object PartageDocument {

    const val CHANNEL = "immo/partage"

    private const val TAG = "ImmoPartage"

    /** WhatsApp d'abord, WhatsApp Business ensuite : le gestionnaire peut avoir les deux. */
    private val PAQUETS_WHATSAPP = listOf("com.whatsapp", "com.whatsapp.w4b")

    /** Les documents servent le temps d'un envoi : au-delà d'un jour, ils encombrent le cache. */
    private const val DUREE_CONSERVATION_MS = 24L * 60 * 60 * 1000

    /** @return "WHATSAPP" si WhatsApp s'est ouvert, "PARTAGE" pour la feuille de partage */
    fun partager(
        activity: Activity,
        nomFichier: String,
        octets: ByteArray,
        mime: String,
        texte: String?,
    ): String {
        val dossier = File(activity.cacheDir, "documents").apply { mkdirs() }
        purger(dossier)
        val fichier = File(dossier, nomFichier).apply { writeBytes(octets) }
        val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.documents", fichier)

        for (paquet in PAQUETS_WHATSAPP) {
            try {
                activity.startActivity(intention(uri, mime, texte).apply { setPackage(paquet) })
                Log.i(TAG, "Document joint et adressé à $paquet, contact à choisir")
                return "WHATSAPP"
            } catch (_: ActivityNotFoundException) {
                // Ce paquet n'est pas installé : on tente le suivant.
            }
        }

        Log.i(TAG, "WhatsApp absent : feuille de partage du système")
        activity.startActivity(Intent.createChooser(intention(uri, mime, texte), "Envoyer la quittance"))
        return "PARTAGE"
    }

    private fun intention(uri: Uri, mime: String, texte: String?) = Intent(Intent.ACTION_SEND).apply {
        type = mime
        putExtra(Intent.EXTRA_STREAM, uri)
        if (!texte.isNullOrBlank()) putExtra(Intent.EXTRA_TEXT, texte)
        // Le ClipData porte l'autorisation de lecture jusqu'à l'application
        // choisie, y compris à travers la feuille de partage.
        clipData = ClipData.newRawUri("", uri)
        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    }

    private fun purger(dossier: File) {
        val limite = System.currentTimeMillis() - DUREE_CONSERVATION_MS
        dossier.listFiles()?.filter { it.lastModified() < limite }?.forEach { it.delete() }
    }
}
