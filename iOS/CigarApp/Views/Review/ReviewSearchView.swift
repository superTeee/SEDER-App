import SwiftUI
import UIKit

/// Neutral catalog/reference search for the App Review build.
/// No featured, top-rated, favorites, wishlist or recommendation modules.
struct ReviewSearchView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var appShell: AppShell
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var cigarService = CigarService()
    @StateObject private var scanService = ScanService()

    @State private var query = ""
    @State private var results: [Cigar] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    @State private var showCameraPicker = false
    @State private var showLibraryPicker = false
    @State private var capturedImage: UIImage?
    @State private var cropRequest: CropRequest?
    @State private var showScanResults = false

    private let humidorService = HumidorService()
    private let receiptService = ReceiptService()
    @State private var humidors: [Humidor] = []
    @State private var receiptImage: UIImage?
    @State private var showReceiptSource = false
    @State private var showReceiptCamera = false
    @State private var showReceiptLibrary = false
    @State private var receiptResult: ReceiptParseResult?
    @State private var isParsingReceipt = false
    @State private var receiptError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background").ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)

                    if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        emptySearchState
                    } else if isSearching {
                        Spacer()
                        ProgressView("Søker…")
                        Spacer()
                    } else {
                        resultList
                    }
                }
            }
            .navigationTitle("Søk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("Background"), for: .navigationBar)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .navigationDestination(isPresented: $showScanResults) {
                ReviewScanResultsView(
                    results: scanService.scanResults,
                    onScanNext: { startNewScan() }
                )
            }
            .sheet(isPresented: $showCameraPicker) {
                ImagePicker(image: $capturedImage, sourceType: .camera) {
                    if let image = capturedImage {
                        Task { await scanService.scanBandImage(image) }
                    }
                }
            }
            .sheet(isPresented: $showLibraryPicker) {
                ImagePicker(image: $capturedImage, sourceType: .photoLibrary) {
                    if let image = capturedImage {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            cropRequest = CropRequest(image: image, ratio: nil)
                        }
                    }
                }
            }
            .fullScreenCover(item: $cropRequest) { req in
                ImageCropper(image: req.image) { cropped in
                    cropRequest = nil
                    capturedImage = cropped
                    Task { await scanService.scanBandImage(cropped) }
                } onCancel: {
                    cropRequest = nil
                }
            }
            .fullScreenCover(isPresented: $scanService.needsShapePhoto) {
                ShapeConfirmView(scanService: scanService)
            }
            .fullScreenCover(isPresented: $scanService.needsWrapperPhoto) {
                WrapperConfirmView(scanService: scanService)
            }
            .sheet(isPresented: $showReceiptSource) {
                ReceiptSourceSheet(
                    onCamera: { showReceiptCamera = true },
                    onLibrary: { showReceiptLibrary = true }
                )
                .presentationDetents([.height(230)])
            }
            .sheet(isPresented: $showReceiptCamera) {
                ImagePicker(image: $receiptImage, sourceType: .camera) {
                    if let image = receiptImage {
                        Task { await parseReceipt(image) }
                    }
                }
            }
            .sheet(isPresented: $showReceiptLibrary) {
                ImagePicker(image: $receiptImage, sourceType: .photoLibrary) {
                    if let image = receiptImage {
                        Task { await parseReceipt(image) }
                    }
                }
            }
            .sheet(item: $receiptResult) { result in
                ReceiptConfirmView(
                    result: result,
                    humidors: humidors,
                    userId: authService.userId ?? UUID(),
                    onFinished: {}
                )
                .environmentObject(authService)
            }
            .alert("Ingen treff", isPresented: $scanService.noMatch) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Vi fant ingen sikker match. Prøv et tydeligere bilde av sigarbåndet.")
            }
            .alert("Feil", isPresented: Binding(
                get: { scanService.errorMessage != nil },
                set: { if !$0 { scanService.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { scanService.errorMessage = nil }
            } message: {
                Text(scanService.errorMessage ?? "")
            }
            .alert("Kunne ikke lese kvitteringen", isPresented: Binding(
                get: { receiptError != nil },
                set: { if !$0 { receiptError = nil } }
            )) {
                Button("OK", role: .cancel) { receiptError = nil }
            } message: {
                Text(receiptError ?? "")
            }
            .overlay {
                if scanService.isScanning || isParsingReceipt {
                    ZStack {
                        Color.black.opacity(0.30).ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView().tint(.white)
                            Text(isParsingReceipt ? "Leser kvitteringen…" : "Identifiserer…")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white)
                        }
                        .padding(24)
                        .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .onChange(of: appShell.pendingScan) { action in
                guard let action else { return }
                switch action {
                case .band: showCameraPicker = true
                case .photo: showLibraryPicker = true
                case .receipt: showReceiptSource = true
                }
                appShell.pendingScan = nil
            }
            .onChange(of: scanService.scanResults) { newResults in
                guard !newResults.isEmpty,
                      !scanService.needsShapePhoto,
                      !scanService.needsWrapperPhoto else { return }
                showScanResults = true
            }
            .onChange(of: scanService.needsShapePhoto) { needsPhoto in
                if !needsPhoto && !scanService.scanResults.isEmpty { showScanResults = true }
            }
            .onChange(of: scanService.needsWrapperPhoto) { needsPhoto in
                if !needsPhoto && !scanService.scanResults.isEmpty { showScanResults = true }
            }
            .onChange(of: query) { newValue in
                scheduleSearch(newValue)
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color("TextSecondary"))
            TextField("Søk etter merke, serie eller vitola…", text: $query)
                .submitLabel(.search)
            if !query.isEmpty {
                Button {
                    query = ""
                    results = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color("TextSecondary"))
                }
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 50)
        .background(colorScheme == .light ? Color.white : Color("Card"))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color("TextSecondary").opacity(0.12), lineWidth: 1)
        )
    }

    private var emptySearchState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 42, weight: .light))
                .foregroundColor(Color("TextSecondary").opacity(0.55))
            Text("Søk i sigarkatalogen")
                .font(.headline)
                .foregroundColor(Color("TextPrimary"))
            Text("Finn registrert produktinformasjon om merke, serie, format og opprinnelse.")
                .font(.subheadline)
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resultList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if results.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 34))
                            .foregroundColor(Color("TextSecondary").opacity(0.55))
                        Text("Ingen treff")
                            .font(.headline)
                        Text("Prøv et annet søk.")
                            .font(.subheadline)
                            .foregroundColor(Color("TextSecondary"))
                    }
                    .padding(.top, 60)
                } else {
                    ForEach(results) { cigar in
                        NavigationLink(destination: ReviewCigarDetailView(cigar: cigar)) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(cigar.brand)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color("TextPrimary"))
                                    let subtitle = [cigar.series, cigar.vitola ?? cigar.commonFormat]
                                        .compactMap { $0 }
                                        .filter { !$0.isEmpty }
                                        .joined(separator: " · ")
                                    if !subtitle.isEmpty {
                                        Text(subtitle)
                                            .font(.subheadline)
                                            .foregroundColor(Color("TextSecondary"))
                                            .lineLimit(1)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(Color("TextSecondary").opacity(0.5))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 13)
                            .background(Color("Card"))
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 80)
        }
    }

    private func scheduleSearch(_ raw: String) {
        searchTask?.cancel()
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            isSearching = false
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await performSearch(trimmed)
        }
    }

    @MainActor
    private func performSearch(_ text: String) async {
        isSearching = true
        defer { isSearching = false }
        do {
            results = try await cigarService.searchCigars(query: text)
        } catch {
            results = []
        }
    }

    private func startNewScan() {
        showScanResults = false
        scanService.scanResults = []
        scanService.extractedText = ""
        capturedImage = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            showCameraPicker = true
        }
    }

    private func parseReceipt(_ image: UIImage) async {
        isParsingReceipt = true
        receiptError = nil
        do {
            if let userId = authService.userId, humidors.isEmpty {
                humidors = (try? await humidorService.fetchHumidors(userId: userId)) ?? []
            }
            let result = try await receiptService.parseReceipt(image: image)
            isParsingReceipt = false
            if result.matched.isEmpty && result.unmatched.isEmpty {
                receiptError = "Fant ingen registrerbare sigarer på kvitteringen. Prøv et tydeligere bilde."
            } else {
                receiptResult = result
            }
        } catch {
            isParsingReceipt = false
            receiptError = "Klarte ikke å lese kvitteringen. Sjekk nettforbindelsen og prøv igjen."
        }
        receiptImage = nil
    }
}

struct ReviewScanResultsView: View {
    let results: [ScanResult]
    let onScanNext: () -> Void

    var body: some View {
        List {
            Section {
                ForEach(results) { result in
                    NavigationLink(destination: ReviewCigarDetailView(cigar: result.cigar)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.cigar.brand)
                                .font(.headline)
                            let subtitle = [result.cigar.series, result.cigar.vitola ?? result.cigar.commonFormat]
                                .compactMap { $0 }
                                .filter { !$0.isEmpty }
                                .joined(separator: " · ")
                            if !subtitle.isEmpty {
                                Text(subtitle)
                                    .font(.subheadline)
                                    .foregroundColor(Color("TextSecondary"))
                            }
                            Text(result.confidenceLabel)
                                .font(.caption)
                                .foregroundColor(Color("TextSecondary"))
                        }
                    }
                }
            } header: {
                Text("Mulige treff")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color("Background"))
        .navigationTitle("Identifisering")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Skann igjen") { onScanNext() }
            }
        }
    }
}
