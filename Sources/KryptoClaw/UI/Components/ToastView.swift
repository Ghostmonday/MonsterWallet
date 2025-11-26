import SwiftUI

struct ToastView: View {
    let message: String
    let iconName: String
    let backgroundColor: Color
    let textColor: Color

    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(textColor)
            Text(message)
                .font(.caption)
                .foregroundColor(textColor)
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(10)
        .shadow(radius: 5)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
