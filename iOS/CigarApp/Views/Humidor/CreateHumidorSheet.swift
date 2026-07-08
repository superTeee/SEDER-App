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

    @State private var photoItem: PhotosPickerItem? = nil
    @State private var photoData: Data? = nil
    @State private var previewImage: Image? = nil

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

                Section("Type") {
                    Picker("Type", selection: $type) {
                        ForEach(HumidorType.allCases) { t in
                            Label(t.displayName, systemImage: t.icon).tag(t)
                        }
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
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        photoData = data
                        if let ui = UIImage(data: data) { previewImage = Image(uiImage: ui) }
                    }
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
    }

    private func save() {
        isSaving = true
        errorMessage = nil
        let capacity = Int(capacityText.trimmingCharacters(in: .whitespaces))
        let loc = location.trimmingCharacters(in: .whitespaces).isEmpty ? nil : location
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        Task {
            do {
                let humidorId: UUID
                if let existing {
                    try await humidorService.updateHumidor(id: existing.id, name: trimmedName, type: type.rawValue, location: loc, capacity: capacity)
                    humidorId = existing.id
                } else {
                    let created = try await humidorService.createHumidor(userId: userId, name: trimmedName, type: type.rawValue, location: loc, capacity: capacity)
                    humidorId = created.id
                }
                if let photoData {
                    _ = try? await humidorService.uploadHumidorCover(humidorId: humidorId, userId: userId, imageData: photoData)
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
