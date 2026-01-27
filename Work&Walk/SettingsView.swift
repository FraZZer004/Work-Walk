//
//  SettingsView.swift
//  Work&Walk
//
//  Created by Alan Krieger on 27/01/2026.
//


import SwiftUI
import SwiftData
import PhotosUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("username") private var username: String = ""
    @AppStorage("userProfileImage") private var userProfileImageBase64: String = ""
    @AppStorage("selectedAppearance") private var selectedAppearance: Int = 0
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "fr"
    @State private var notificationsEnabled = true; @State private var selectedPhotoItem: PhotosPickerItem? = nil; @State private var currentAvatar: UIImage? = nil
    var body: some View {
        NavigationStack {
            List {
                Section { VStack(spacing: 15) { ZStack(alignment: .topTrailing) { PhotosPicker(selection: $selectedPhotoItem, matching: .images) { ZStack { if let avatar = currentAvatar { Image(uiImage: avatar).resizable().scaledToFill().frame(width: 100, height: 100).clipShape(Circle()).overlay(Circle().stroke(Color.orange, lineWidth: 2)) } else { Circle().fill(Color(UIColor.systemGray5)).frame(width: 100, height: 100).overlay(Image(systemName: "person.fill").font(.system(size: 40)).foregroundStyle(.gray)) }; Circle().fill(.orange).frame(width: 30, height: 30).overlay(Image(systemName: "pencil").foregroundStyle(.white).font(.caption)).offset(x: 35, y: 35) } }.buttonStyle(.plain); if currentAvatar != nil { Button(action: deleteAvatar) { Image(systemName: "xmark.circle.fill").symbolRenderingMode(.palette).foregroundStyle(.white, .red).font(.system(size: 26)).background(Circle().fill(.white).frame(width: 20, height: 20)) }.offset(x: 5, y: -5).buttonStyle(.plain) } }; VStack(spacing: 5) { Text("Ton Prénom").font(.caption).foregroundStyle(.secondary).textCase(.uppercase); TextField("Entre ton prénom", text: $username).font(.title2).bold().multilineTextAlignment(.center).submitLabel(.done) } }.frame(maxWidth: .infinity).padding(.vertical, 10).listRowBackground(Color.clear) }
                Section(header: Text("Apparence")) { Picker("Thème", selection: $selectedAppearance) { Text("Système").tag(0); Text("Clair").tag(1); Text("Sombre").tag(2) }.pickerStyle(.segmented).listRowSeparator(.hidden); Picker("Langue", selection: $selectedLanguage) { Text("Français").tag("fr"); Text("English").tag("en") } }
                Section(header: Text("Préférences")) { Toggle(isOn: $notificationsEnabled) { Label { Text("Rappels d'horaires") } icon: { Image(systemName: "bell.badge.fill").foregroundStyle(.red) } }.onChange(of: notificationsEnabled) { _, isEnabled in if isEnabled { NotificationManager.shared.scheduleAllNotifications() } else { NotificationManager.shared.cancelAll() } }; Toggle(isOn: .constant(true)) { Label { Text("Données Santé") } icon: { Image(systemName: "heart.fill").foregroundStyle(.pink) } }.disabled(true); Text("Pour gérer l'accès Santé, allez dans Réglages > Santé > Work&Walk.").font(.caption2).foregroundStyle(.secondary) }
                Section(header: Text("Informations Légales")) { NavigationLink { PrivacyPolicyView() } label: { Label("Politique de Confidentialité", systemImage: "hand.raised.fill") }; NavigationLink { LegalDetailView(title: "Avertissement Financier", content: "L'application Work&Walk propose des estimations de salaire basées sur les données saisies par l'utilisateur.\nCes calculs sont fournis à titre purement indicatif et ne sauraient remplacer une fiche de paie officielle. L'éditeur décline toute responsabilité en cas d'écart avec le salaire réel.") } label: { Label("Avertissement Financier", systemImage: "banknote.fill") }; NavigationLink { LegalDetailView(title: "Avertissement Santé", content: "Les données de santé proviennent d'Apple HealthKit.\nWork&Walk n'est pas un dispositif médical. Consultez toujours un médecin avant de commencer un programme sportif intensif.") } label: { Label("Avertissement Santé", systemImage: "staroflife.fill") } }
                Section(footer: Text("Cette action est irréversible.").font(.caption)) { Button(role: .destructive) { } label: { Label("Réinitialiser les données", systemImage: "trash.fill").foregroundStyle(.red) } }
                Section { HStack { Spacer(); VStack(spacing: 5) { Image("AppLogo").resizable().scaledToFit().frame(width: 60, height: 60).opacity(0.9); Text("Work&Walk").font(.headline); Text("Version 1.0.2").font(.caption).foregroundStyle(.secondary); Text("© 2026 Tous droits réservés").font(.caption2).foregroundStyle(.tertiary) }; Spacer() }.listRowBackground(Color.clear) }
            }.navigationTitle("Paramètres").navigationBarTitleDisplayMode(.inline).toolbar { Button("OK") { dismiss() }.fontWeight(.bold).foregroundStyle(.orange) }.preferredColorScheme(selectedAppearance == 1 ? .light : (selectedAppearance == 2 ? .dark : nil)).id(selectedAppearance).onAppear { loadAvatar() }.onChange(of: selectedPhotoItem) { _, newItem in Task { if let data = try? await newItem?.loadTransferable(type: Data.self), let uiImage = UIImage(data: data), let compressedData = uiImage.jpegData(compressionQuality: 0.5) { userProfileImageBase64 = compressedData.base64EncodedString(); currentAvatar = uiImage } } }
        }
    }
    func loadAvatar() { if !userProfileImageBase64.isEmpty, let data = Data(base64Encoded: userProfileImageBase64) { currentAvatar = UIImage(data: data) } }
    func deleteAvatar() { withAnimation { currentAvatar = nil; userProfileImageBase64 = ""; selectedPhotoItem = nil } }
}

struct LegalDetailView: View { let title: String; let content: String; var body: some View { ScrollView { Text(content).padding().font(.body) }.navigationTitle(title) } }
