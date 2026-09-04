import SwiftUI
import PhotosUI
import Kingfisher

// MARK: - CreateHumidorSheet
// Opprett eller rediger en humidor. Felter: navn, type, lokasjon, kapasitet, bilde.

struct CreateHumidorSheet: View {

    var existing: Humidor? = nil          // nil = opprett, satt = rediger
    let userId: UUID
    var onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    private let humidorService = HumidorService()

    @State private var name = ""
    @State private var type: HumidorType = .desktop
    @State private var location = ""
    @State private var capacityText = ""
    @State private var targetRhText = ""
    @State private var rhMinText = ""
    @State private var rhMaxText = ""

    @State private var photoItem: PhotosPickerItem? = nil
    @State private var photoData: Data? = nil
    @State private var previewImage: Image? = nil
    @State private var cropRequest: CropRequest? = nil

    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                // Bilde
                Section {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        HStack(spacing: 14) {
                            imageThumb
                            Text(previewImage != nil || existing?.imageURL != nil ? "Bytt bilde" : "Legg til bilde")
                                .foregroundColor(Color("Accent"))
                            Spacer()
                            Image(systemName: "photo.on.rectangle")
                                .foregroundColor(Color("TextSecondary"))
                        }
                    }
                }

                Section("Navn") {
                    TextField("F.eks. Hjemme-humidoren", text: $name)
                        .textInputAutocapitalization(.words)
                }

                // Radio-liste: hver type viser tittel + forklaring fra første sekund.
                Section("Type") {
                    ForEach(HumidorType.allCases) { t in
                        Button {
                            type = t
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: type == t ? "largecircle.fill.circle" : "circle")
                                    .foregroundColor(type == t ? Color("Accent") : Color(.tertiaryLabel))
                                    .font(.system(size: 20))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(t.displayName)
                                        .font(.body)
                                        .foregroundColor(Color(.label))
                                    Text(t.explanation)
                                        .font(.caption)
                                        .foregroundColor(Color(.secondaryLabel))
                                }
                                Spacer(minLength: 0)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("Lokasjon") {
                    TextField("F.eks. Hytta, Hjemme", text: $location)
                        .textInputAutocapitalization(.words)
                }

                Section("Kapasitet") {
                    HStack {
                        TextField("F.eks. 30", text: $capacityText)
                            .keyboardType(.numberPad)
                        Text("sigarer").foregroundColor(Color("TextSecondary"))
                    }
                }

                Section {
                    HStack {
                        TextField("F.eks. 69", text: $targetRhText)
                            .keyboardType(.numberPad)
                        Text("% mål-RH").foregroundColor(Color("TextSecondary"))
                    }
                    HStack {
                        TextField("Fra", text: $rhMinText).keyboardType(.numberPad)
                        Text("–").foregroundColor(Color("TextSecondary"))
                        TextField("Til", text: $rhMaxText).keyboardType(.numberPad)
                        Text("% (valgfritt)").foregroundColor(Color("TextSecondary"))
                    }
                } header: {
                    Text("Luftfuktighet (RH)")
                } footer: {
                    Text("RH står for relativ luftfuktighet — hvor fuktig det er inne i humidoren. Sett gjerne et mål (f.eks. 69 %) og et valgfritt akseptabelt område.")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage).font(.caption).foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(existing == nil ? "Ny humidor" : "Rediger humidor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existing == nil ? "Opprett" : "Lagre") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .onChange(of: photoItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let ui = UIImage(data: data) {
                        cropRequest = CropRequest(image: ui, ratio: 1.7)  // bredt cover
                    }
                    photoItem = nil
                }
            }
            .fullScreenCover(item: $cropRequest) { req in
                ImageCropper(image: req.image, ratio: req.ratio) { cropped in
                    cropRequest = nil
                    photoData = cropped.jpegData(compressionQuality: 0.9)
                    previewImage = Image(uiImage: cropped)
                } onCancel: {
                    cropRequest = nil
                }
            }
            .onAppear(perform: prefill)
        }
    }

    @ViewBuilder
    private var imageThumb: some View {
        if let previewImage {
            previewImage.resizable().scaledToFill()
                .frame(width: 56, height: 56).clipShape(RoundedRectangle(cornerRadius: 8))
        } else if let urlStr = existing?.imageURL, let url = URL(string: urlStr) {
            KFImage(url)
                .resizable()
                .placeholder { placeholderThumb }
                .scaledToFill()
                .frame(width: 56, height: 56).clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            placeholderThumb
        }
    }

    private var placeholderThumb: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(Color("Accent").opacity(0.12))
                .frame(width: 56, height: 56)
            Image(systemName: type.icon).foregroundColor(Color("Accent"))
        }
    }

    private func prefill() {
        guard let existing else { return }
        name = existing.name
        type = existing.typeEnum ?? .desktop
        location = existing.location ?? ""
        if let cap = existing.capacity { capacityText = String(cap) }
        if let t = existing.targetRh { targetRhText = String(t) }
        if let lo = existing.rhMin { rhMinText = String(lo) }
        if let hi = existing.rhMax { rhMaxText = String(hi) }
    }

    private func save() {
        isSaving = true
        errorMessage = nil
        let capacity = Int(capacityText.trimmingCharacters(in: .whitespaces))
        let loc = location.trimmingCharacters(in: .whitespaces).isEmpty ? nil : location
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let targetRh = Int(targetRhText.trimmingCharacters(in: .whitespaces))
        let rhMin = Int(rhMinText.trimmingCharacters(in: .whitespaces))
        let rhMax = Int(rhMaxText.trimmingCharacters(in: .whitespaces))
        Task {
            do {
                let humidorId: UUID
                if let existing {
                    try await humidorService.updateHumidor(id: existing.id, name: trimmedName, type: type.rawValue, location: loc, capacity: capacity,
                                                           targetRh: targetRh, rhMin: rhMin, rhMax: rhMax)
                    humidorId = existing.id
                } else {
                    let created = try await humidorService.createHumidor(userId: userId, name: trimmedName, type: type.rawValue, location: loc, capacity: capacity,
                                                                         targetRh: targetRh, rhMin: rhMin, rhMax: rhMax)
                    humidorId = created.id
                }
                if let photoData {
                    await attempt("Last opp humidor-cover") {
                        try await humidorService.uploadHumidorCover(humidorId: humidorId, userId: userId, imageData: photoData)
                    }
                }
                onSaved()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}
