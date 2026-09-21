import SwiftUI

struct DeadlineBadgeView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var fontSize = 48.0
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .monospacedDigit()
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.primary)
            .minimumScaleFactor(0.7)
            .lineLimit(1)
    }
}

#Preview {
    DeadlineBadgeView(text: "D-62")
        .padding()
}
