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

    private let cigarService = CigarService()

    // MARK: - Hovedfunksjon: scan et bilde
    func scanBandImage(_ image: UIImage) async {
        isScanning = true
        scanResults = []
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
        for match in aiResults {
            if let cigar = try? await cigarService.fetchCigar(id: match.cigarId) {
                scanResults.append(ScanResult(
                    cigar: cigar,
                    confidence: match.confidence,
                    matchReason: match.reason
                ))
            }
        }
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

    enum CodingKeys: String, CodingKey {
        case cigarId    = "cigar_id"
        case confidence
        case reason
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
