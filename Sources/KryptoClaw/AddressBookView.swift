import SwiftUI

struct AddressBookView: View {
    @EnvironmentObject var wsm: WalletStateManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showAddSheet = false
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundMain.ignoresSafeArea()
            
            VStack(spacing: 0) {
                KryptoHeader(
                    title: "Address Book",
                    onBack: { presentationMode.wrappedValue.dismiss() },
                    actionIcon: "plus",
                    onAction: { showAddSheet = true }
                )
                
                if wsm.contacts.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 64))
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                        Text("No contacts yet")
                            .font(themeManager.currentTheme.font(style: .headline))
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(wsm.contacts) { contact in
                            KryptoListRow(
                                title: contact.name,
                                subtitle: contact.address,
                                value: nil,
                                icon: "person.circle.fill",
                                isSystemIcon: true
                            )
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .padding(.vertical, 4)
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { index in
                                let contact = wsm.contacts[index]
                                wsm.removeContact(id: contact.id)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddContactView(isPresented: $showAddSheet)
        }
        .onAppear {
            // Telemetry
            print("[AddressBook] ViewDidAppear")
        }
    }
}

struct AddContactView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var wsm: WalletStateManager
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var name = ""
    @State private var address = ""
    @State private var note = ""
    @State private var error: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundMain.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    KryptoInput(title: "Name", placeholder: "Alice", text: $name)
                    KryptoInput(title: "Address", placeholder: "0x...", text: $address)
                    KryptoInput(title: "Note (Optional)", placeholder: "Friend", text: $note)
                    
                    if let err = error {
                        Text(err)
                            .foregroundColor(themeManager.currentTheme.errorColor)
                            .font(themeManager.currentTheme.font(style: .caption))
                    }
                    
                    Spacer()
                    
                    KryptoButton(
                        title: "Save Contact",
                        icon: "checkmark.circle.fill",
                        action: saveContact,
                        isPrimary: true
                    )
                }
                .padding()
                .navigationTitle("Add Contact")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { isPresented = false }
                    }
                }
            }
        }
    }
    
    func saveContact() {
        // Validation
        guard !name.isEmpty else {
            error = "Name is required"
            return
        }
        
        // Simple regex for 0x address
        let addressRegex = "^0x[a-fA-F0-9]{40}$"
        guard address.range(of: addressRegex, options: .regularExpression) != nil else {
            error = "Invalid Ethereum address format"
            return
        }
        
        let contact = Contact(name: name, address: address, note: note.isEmpty ? nil : note)
        wsm.addContact(contact)
        
        // Telemetry
        Telemetry.shared.logEvent("Contact Added", parameters: ["name": name])
        
        isPresented = false
    }
}

