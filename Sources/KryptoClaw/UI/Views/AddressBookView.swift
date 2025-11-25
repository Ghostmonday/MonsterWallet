import SwiftUI

struct AddressBookView: View {
    @EnvironmentObject var wsm: WalletStateManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode

    @State private var showAddSheet = false

    var body: some View {
        let theme = themeManager.currentTheme
        
        ZStack {
            Color.clear
                .themedContainer(theme: theme, showPattern: true, applyAnimation: true)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                KryptoHeader(
                    title: "Address Book",
                    onBack: { presentationMode.wrappedValue.dismiss() },
                    actionIcon: "plus",
                    onAction: { showAddSheet = true }
                )

                if wsm.contacts.isEmpty {
                    KryptoEmptyState(
                        icon: "person.crop.circle.badge.plus",
                        title: "No Contacts",
                        message: "Add your first contact to easily send crypto to friends and family"
                    )
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
                            .padding(.vertical, theme.spacingXS)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
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
            KryptoLogger.shared.log(level: .info, category: .lifecycle, message: "ViewDidAppear", metadata: ["view": "AddressBook"])
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
        let theme = themeManager.currentTheme
        
        NavigationView {
            ZStack {
                Color.clear
                    .themedContainer(theme: theme, showPattern: true, applyAnimation: true)
                    .ignoresSafeArea()

                VStack(spacing: theme.spacingXL) {
                    KryptoInput(title: "Name", placeholder: "Alice", text: $name)
                    KryptoInput(title: "Address", placeholder: "0x...", text: $address)
                    KryptoInput(title: "Note (Optional)", placeholder: "Friend", text: $note)

                    if let err = error {
                        Text(err)
                            .foregroundColor(theme.errorColor)
                            .font(theme.captionFont)
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
                                .foregroundColor(theme.accentColor)
                        }
                    }
            }
        }
    }

    func saveContact() {
        guard !name.isEmpty else {
            error = "Name is required"
            return
        }

        let addressRegex = "^0x[a-fA-F0-9]{40}$"
        guard address.range(of: addressRegex, options: .regularExpression) != nil else {
            error = "Invalid Ethereum address format"
            return
        }

        let contact = Contact(name: name, address: address, note: note.isEmpty ? nil : note)
        wsm.addContact(contact)
        Telemetry.shared.logEvent("Contact Added", parameters: ["name": name])

        isPresented = false
    }
}
