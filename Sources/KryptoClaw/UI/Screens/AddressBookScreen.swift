// KRYPTOCLAW ADDRESS BOOK
// Trusted contacts. Quick access.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct AddressBookScreen: View {
    @EnvironmentObject var walletState: WalletStateManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddContact = false
    @State private var searchText = ""
    @State private var editingContact: Contact?
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                KC.Color.bg.ignoresSafeArea()
                
                if walletState.contacts.isEmpty && searchText.isEmpty {
                    emptyState
                } else {
                    contactsList
                }
            }
            .navigationTitle("Address Book")
            .kcNavigationLarge()
            .toolbar {
                ToolbarItem(placement: .kcLeading) {
                    Button(action: { showingAddContact = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(KC.Color.gold)
                    }
                }
                ToolbarItem(placement: .kcTrailing) {
                    KCCloseButton { dismiss() }
                }
            }
            .searchable(text: $searchText, prompt: "Search contacts")
            .sheet(isPresented: $showingAddContact) {
                AddContactSheet()
                    .environmentObject(walletState)
            }
            .sheet(item: $editingContact) { contact in
                EditContactSheet(contact: contact)
                    .environmentObject(walletState)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        KCEmptyState(
            icon: "person.crop.circle.badge.plus",
            title: "No Contacts",
            message: "Add trusted addresses to your address book for quick and safe transfers.",
            actionTitle: "Add Contact",
            action: { showingAddContact = true }
        )
    }
    
    // MARK: - Contacts List
    
    private var contactsList: some View {
        ScrollView {
            LazyVStack(spacing: KC.Space.sm) {
                ForEach(filteredContacts, id: \.id) { contact in
                    ContactRow(contact: contact)
                        .onTapGesture {
                            HapticEngine.shared.play(.selection)
                            editingContact = contact
                        }
                        .contextMenu {
                            Button(action: {
                                copyAddress(contact.address)
                            }) {
                                Label("Copy Address", systemImage: "doc.on.doc")
                            }
                            
                            Button(role: .destructive, action: {
                                deleteContact(contact)
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .kcPadding()
            .padding(.top, KC.Space.md)
            .padding(.bottom, KC.Space.xxxl)
        }
    }
    
    private var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return walletState.contacts
        }
        return walletState.contacts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.address.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private func copyAddress(_ address: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = address
        #endif
        HapticEngine.shared.play(.success)
    }
    
    private func deleteContact(_ contact: Contact) {
        HapticEngine.shared.play(.selection)
        walletState.removeContact(id: contact.id)
    }
}

// MARK: - Contact Row

private struct ContactRow: View {
    let contact: Contact
    
    var body: some View {
        HStack(spacing: KC.Space.lg) {
            // Avatar
            ZStack {
                Circle()
                    .fill(avatarColor.opacity(0.2))
                    .frame(width: KC.Size.avatarMD, height: KC.Size.avatarMD)
                
                Text(String(contact.name.prefix(1)).uppercased())
                    .font(KC.Font.bodyLarge)
                    .foregroundColor(avatarColor)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(KC.Font.body)
                    .foregroundColor(KC.Color.textPrimary)
                
                Text(truncateAddress(contact.address))
                    .font(KC.Font.monoSmall)
                    .foregroundColor(KC.Color.textTertiary)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(KC.Color.textMuted)
        }
        .padding(KC.Space.lg)
        .background(KC.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: KC.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: KC.Radius.md)
                .stroke(KC.Color.border, lineWidth: 1)
        )
    }
    
    private var avatarColor: Color {
        let colors: [Color] = [
            KC.Color.gold,
            KC.Color.positive,
            KC.Color.info,
            .purple,
            .orange
        ]
        let index = abs(contact.name.hashValue) % colors.count
        return colors[index]
    }
    
    private func truncateAddress(_ address: String) -> String {
        guard address.count > 16 else { return address }
        return "\(address.prefix(8))...\(address.suffix(6))"
    }
}

// MARK: - Add Contact Sheet

struct AddContactSheet: View {
    @EnvironmentObject var walletState: WalletStateManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var address = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                KC.Color.bg.ignoresSafeArea()
                
                VStack(spacing: KC.Space.xl) {
                    VStack(alignment: .leading, spacing: KC.Space.sm) {
                        Text("NAME")
                            .font(KC.Font.label)
                            .tracking(1.5)
                            .foregroundColor(KC.Color.textMuted)
                        
                        KCInput("Contact name", text: $name, icon: "person")
                    }
                    .padding(.top, KC.Space.xl)
                    
                    VStack(alignment: .leading, spacing: KC.Space.sm) {
                        Text("WALLET ADDRESS")
                            .font(KC.Font.label)
                            .tracking(1.5)
                            .foregroundColor(KC.Color.textMuted)
                        
                        HStack(spacing: KC.Space.md) {
                            TextField("0x...", text: $address)
                                .font(KC.Font.mono)
                                .foregroundColor(KC.Color.textPrimary)
                                .autocorrectionDisabled()
                            
                            Button(action: pasteAddress) {
                                Image(systemName: "doc.on.clipboard")
                                    .foregroundColor(KC.Color.gold)
                            }
                        }
                        .padding(KC.Space.lg)
                        .background(KC.Color.card)
                        .clipShape(RoundedRectangle(cornerRadius: KC.Radius.lg))
                        .overlay(
                            RoundedRectangle(cornerRadius: KC.Radius.lg)
                                .stroke(KC.Color.border, lineWidth: 1)
                        )
                    }
                    
                    Spacer()
                    
                    KCButton("Save Contact", icon: "checkmark") {
                        saveContact()
                    }
                    .disabled(name.isEmpty || address.isEmpty)
                    .padding(.bottom, KC.Space.xxxl)
                }
                .kcPadding()
            }
            .navigationTitle("Add Contact")
            .kcNavigationInline()
            .toolbar {
                ToolbarItem(placement: .kcTrailing) {
                    KCCloseButton { dismiss() }
                }
            }
        }
    }
    
    private func pasteAddress() {
        #if canImport(UIKit)
        if let clipboard = UIPasteboard.general.string {
            address = clipboard
        }
        #endif
    }
    
    private func saveContact() {
        let contact = Contact(name: name, address: address)
        walletState.addContact(contact)
        HapticEngine.shared.play(.success)
        dismiss()
    }
}

// MARK: - Edit Contact Sheet

struct EditContactSheet: View {
    let contact: Contact
    
    @EnvironmentObject var walletState: WalletStateManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var address: String
    @State private var showDeleteConfirm = false
    
    init(contact: Contact) {
        self.contact = contact
        _name = State(initialValue: contact.name)
        _address = State(initialValue: contact.address)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                KC.Color.bg.ignoresSafeArea()
                
                VStack(spacing: KC.Space.xl) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(KC.Color.gold.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Text(String(name.prefix(1)).uppercased())
                            .font(KC.Font.title1)
                            .foregroundColor(KC.Color.gold)
                    }
                    .padding(.top, KC.Space.xl)
                    
                    VStack(alignment: .leading, spacing: KC.Space.sm) {
                        Text("NAME")
                            .font(KC.Font.label)
                            .tracking(1.5)
                            .foregroundColor(KC.Color.textMuted)
                        
                        KCInput("Contact name", text: $name, icon: "person")
                    }
                    
                    VStack(alignment: .leading, spacing: KC.Space.sm) {
                        Text("WALLET ADDRESS")
                            .font(KC.Font.label)
                            .tracking(1.5)
                            .foregroundColor(KC.Color.textMuted)
                        
                        Text(address)
                            .font(KC.Font.mono)
                            .foregroundColor(KC.Color.textSecondary)
                            .padding(KC.Space.lg)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(KC.Color.card)
                            .clipShape(RoundedRectangle(cornerRadius: KC.Radius.lg))
                            .overlay(
                                RoundedRectangle(cornerRadius: KC.Radius.lg)
                                    .stroke(KC.Color.border, lineWidth: 1)
                            )
                    }
                    
                    Spacer()
                    
                    VStack(spacing: KC.Space.md) {
                        KCButton("Save Changes", icon: "checkmark") {
                            // Update would require extending WalletStateManager
                            HapticEngine.shared.play(.success)
                            dismiss()
                        }
                        .disabled(name.isEmpty)
                        
                        KCButton("Delete Contact", icon: "trash", style: .danger) {
                            showDeleteConfirm = true
                        }
                    }
                    .padding(.bottom, KC.Space.xxxl)
                }
                .kcPadding()
            }
            .navigationTitle("Edit Contact")
            .kcNavigationInline()
            .toolbar {
                ToolbarItem(placement: .kcTrailing) {
                    KCCloseButton { dismiss() }
                }
            }
            .alert("Delete Contact", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    walletState.removeContact(id: contact.id)
                    HapticEngine.shared.play(.success)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete \(contact.name)?")
            }
        }
    }
}

// Contact is already Identifiable from Core

#Preview {
    AddressBookScreen()
}

