// Encore/Views/Components/CrewAvatarBubble.swift
import SwiftUI

struct CrewAvatarBubble: View {
    let member: CrewMember
    let size: CGFloat

    init(member: CrewMember, size: CGFloat = 36) {
        self.member = member
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(member.color)
                .frame(width: size, height: size)
            Text(member.initials)
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundColor(Color.appBackground)
        }
    }
}

#Preview {
    CrewAvatarBubble(member: Crew.mockCrew.members[0], size: 36)
        .preferredColorScheme(.dark)
}
