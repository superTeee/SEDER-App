import Foundation
import Vision
import UIKit

// MARK: - ScanService
// Steg 1: Apple Vision OCR (gratis, on-device)
// Steg 2: Supabase-søk basert på tekst
// Steg 3 (fallback): GPT-4o Vision via Supabase Edge Function

@MainActor
class ScanService: ObservableObject {

    @Published var isScanning = false
    @Published var extractedText: String = ""
    @Published var scanResults: [ScanResult] = []
    @Published var errorMessage: String?
    // Satt når båndet/AI-en eksplisitt pekte ut én bestemt variant —
    // da hopper appen rett til detaljskjermen i stedet for en velgerliste.
    @Published var autoSelectedCigar: Cigar?

    private let cigarService = CigarService()

    // MARK: - Hovedfunksjon: scan et bilde
    func scanBandImage(_ image: UIImage) async {
        isScanning = true
        scanResults = []
        autoSelectedCigar = nil
        errorMessage = nil

        do {
            // Steg 1: Trekk ut tekst med Apple Vision (OCR)
            let text = try await extractText(from: image)
            extractedText = text
            print("📝 OCR-tekst: \(text)")

            // Steg 2: Søk i databasen
            if !text.isEmpty {
                let cigars = try await cigarService.searchCigars(query: text)

                if !cigars.isEmpty {
                    // Konverter til ScanResult med konfidensberegning
                    scanResults = cigars.enumerated().map { index, cigar in
                        ScanResult(
                            cigar: cigar,
                            confidence: confidenceScore(for: cigar, ocrText: text, rank: index),
                            matchReason: "Tekst: \(text)"
                        )
                    }

                    // Nevner båndet eksplisitt én bestemt serie/variant?
                    // Da slipper brukeren å velge selv.
                    autoSelectedCigar = exactSeriesMatch(in: cigars, ocrText: text)
                } else {
                    // Steg 3: Fallback til GPT-4o via Edge Function
                    try await scanWithAI(image: image)
                }
            } else {
                // Ingen tekst funnet — bruk AI direkte
                try await scanWithAI(image: image)
            }

        } catch {
            errorMessage = "Scanning feilet: \(error.localizedDescription)"
        }

        if errorMessage == nil && scanResults.isEmpty {
            errorMessage = "Fant ingen treff for denne sigaren. Prøv et tydeligere bilde av båndet, eller søk den opp manuelt."
        }

        isScanning = false
    }

    // MARK: - Apple Vision OCR
    private func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw ScanError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                continuation.resume(returning: text)
            }

            // Høy nøyaktighet — tregere men bedre for sigarbelt-tekst
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US", "es-ES"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - AI Fallback via Supabase Edge Function
    // Edge Function holder OpenAI API-nøkkelen server-side (tryggere)
    private func scanWithAI(image: UIImage) async throws {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw ScanError.invalidImage
        }

        let base64Image = imageData.base64EncodedString()

        // Kall Supabase Edge Function "scan-cigar" — dekoder responsen direkte til [AICigarMatch]
        let aiResults: [AICigarMatch] = try await supabase.functions
            .invoke(
                "scan-cigar",
                options: .init(
                    body: ["image": base64Image, "ocr_text": extractedText]
                )
            )

        // Hent fulle cigar-objekter for hvert AI-treff
        var exactMatches: [Cigar] = []
        for match in aiResults {
            if let cigar = try? await cigarService.fetchCigar(id: match.cigarId) {
                scanResults.append(ScanResult(
                    cigar: cigar,
                    confidence: match.confidence,
                    matchReason: match.reason
                ))
                if match.exactMatch {
                    exactMatches.append(cigar)
                }
            }
        }

        // AI-en/båndet pekte eksplisitt på akkurat én variant — velg den
        // automatisk. Er det flere eksakte treff (usikkert), la brukeren velge.
        if exactMatches.count == 1 {
            autoSelectedCigar = exactMatches.first
        }
    }

    // MARK: - Eksplisitt variant-gjenkjenning fra OCR-tekst
    // Returnerer cigaren hvis AKKURAT ÉN av treffene har en serie som
    // faktisk står skrevet i OCR-teksten fra båndet.
    private func exactSeriesMatch(in cigars: [Cigar], ocrText: String) -> Cigar? {
        let text = ocrText.lowercased()
        let candidates = cigars.filter { cigar in
            guard let series = cigar.series, series.count > 2 else { return false }
            return text.contains(series.lowercased())
        }
        return candidates.count == 1 ? candidates.first : nil
    }

    // MARK: - Konfidensberegning (enkel heuristikk)
    private func confidenceScore(for cigar: Cigar, ocrText: String, rank: Int) -> Double {
        let text = ocrText.lowercased()
        var score = 1.0 - (Double(rank) * 0.15) // Lavere rank = høyere konfidensgrunnlag

        // Boost hvis merket finnes eksplisitt i OCR-teksten
        if text.contains(cigar.brand.lowercased()) {
            score += 0.2
        }
        if let series = cigar.series, text.contains(series.lowercased()) {
            score += 0.15
        }

        return min(score, 1.0)
    }
}

// MARK: - AI Match (respons fra Edge Function)
struct AICigarMatch: Decodable {
    let cigarId: UUID
    let confidence: Double
    let reason: String
    let exactMatch: Bool

    enum CodingKeys: String, CodingKey {
        case cigarId    = "cigar_id"
        case confidence
        case reason
        case exactMatch = "exact_match"
    }
}

// MARK: - Feil
enum ScanError: LocalizedError {
    case invalidImage
    case noTextFound
    case noMatchFound

    var errorDescription: String? {
        switch self {
        case .invalidImage:     return "Bildet kunne ikke behandles. Prøv igjen."
        case .noTextFound:      return "Ingen tekst funnet på bandet."
        case .noMatchFound:     return "Fant ingen matchende sigarer."
        }
    }
}
