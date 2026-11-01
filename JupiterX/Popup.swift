import SwiftUI

public enum PopupPlacement {
    case center
    case top
    case bottom
    case leading
    case trailing

    var alignment: Alignment {
        switch self {
        case .center: return .center
        case .top: return .top
        case .bottom: return .bottom
        case .leading: return .leading
        case .trailing: return .trailing
        }
    }
}

public struct Popup: View {
    // Controls presentation externally
    @Binding var isPresented: Bool

    // Content parameters
    var title: String?
    var message: String?
    var systemImage: String?

    // Button parameters
    var primaryButtonTitle: String
    var primaryButtonRole: ButtonRole?
    var primaryButtonAction: (() -> Void)?

    // Optional secondary button
    var secondaryButtonTitle: String?
    var secondaryButtonRole: ButtonRole?
    var secondaryButtonAction: (() -> Void)?

    // Appearance
    var accentColor: Color
    var showsCloseButton: Bool
    var placement: PopupPlacement

    public init(
        isPresented: Binding<Bool>,
        title: String? = nil,
        message: String? = nil,
        systemImage: String? = nil,
        primaryButtonTitle: String = "OK",
        primaryButtonRole: ButtonRole? = nil,
        accentColor: Color = .accentColor,
        showsCloseButton: Bool = true,
        placement: PopupPlacement = .center,
        primaryButtonAction: (() -> Void)? = nil,
        secondaryButtonTitle: String? = nil,
        secondaryButtonRole: ButtonRole? = nil,
        secondaryButtonAction: (() -> Void)? = nil
    ) {
        self._isPresented = isPresented
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.primaryButtonTitle = primaryButtonTitle
        self.primaryButtonRole = primaryButtonRole
        self.primaryButtonAction = primaryButtonAction
        self.secondaryButtonTitle = secondaryButtonTitle
        self.secondaryButtonRole = secondaryButtonRole
        self.secondaryButtonAction = secondaryButtonAction
        self.accentColor = accentColor
        self.showsCloseButton = showsCloseButton
        self.placement = placement
    }

    private var cardView: some View {
        VStack(spacing: 16) {
            if showsCloseButton {
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.spring(duration: 0.25)) { isPresented = false }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .accessibilityLabel("Close")
                }
            }

            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 42))
                    .foregroundStyle(accentColor)
                    .padding(.top, showsCloseButton ? 0 : 12)
            }

            if let title, !title.isEmpty {
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if let message, !message.isEmpty {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: 10) {
                if let secondaryButtonTitle {
                    Button(role: secondaryButtonRole) {
                        secondaryButtonAction?()
                        withAnimation(.spring(duration: 0.25)) { isPresented = false }
                    } label: {
                        Text(secondaryButtonTitle)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                Button(role: primaryButtonRole) {
                    primaryButtonAction?()
                    withAnimation(.spring(duration: 0.25)) { isPresented = false }
                } label: {
                    Text(primaryButtonTitle)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(accentColor)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: 360)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .shadow(radius: 12)
    }

    private func edgeInsetsForPlacement() -> EdgeInsets {
        switch placement {
        case .center:
            return EdgeInsets()
        case .top:
            return EdgeInsets(top: 24, leading: 16, bottom: 0, trailing: 16)
        case .bottom:
            return EdgeInsets(top: 0, leading: 16, bottom: 34, trailing: 16)
        case .leading:
            return EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 0)
        case .trailing:
            return EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 16)
        }
    }

    private func transitionForPlacement() -> AnyTransition {
        switch placement {
        case .center:
            return .scale.combined(with: .opacity)
        case .top:
            return .move(edge: .top).combined(with: .opacity)
        case .bottom:
            return .move(edge: .bottom).combined(with: .opacity)
        case .leading:
            return .move(edge: .leading).combined(with: .opacity)
        case .trailing:
            return .move(edge: .trailing).combined(with: .opacity)
        }
    }

    public var body: some View {
        ZStack(alignment: placement.alignment) {
            // Dimmed background
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { withAnimation(.spring(duration: 0.25)) { isPresented = false } }

            // Card
            cardView
                .padding(edgeInsetsForPlacement())
                .transition(transitionForPlacement())
        }
        .opacity(isPresented ? 1 : 0)
        .allowsHitTesting(isPresented)
        .animation(.spring(response: 0.3, dampingFraction: 0.9), value: isPresented)
    }
}

// MARK: - Presentation Modifier
public struct PopupPresenter<PopupContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let popupContent: () -> PopupContent

    public func body(content: Content) -> some View {
        ZStack {
            content
            if isPresented {
                popupContent()
            }
        }
    }
}

public extension View {
    /// Presents a popup overlay when `isPresented` is true.
    /// - Parameters:
    ///   - isPresented: Binding that controls presentation.
    ///   - content: The popup content to display.
    func popup<PopupContent: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> PopupContent) -> some View {
        modifier(PopupPresenter(isPresented: isPresented, popupContent: content))
    }
}

#Preview {
    struct Demo: View {
        @State private var show = true
        var body: some View {
            ZStack {
                Color.blue.opacity(0.1)
                    .ignoresSafeArea()
                Button("Toggle Popup") { show.toggle() }
                .padding()
            }
            .popup(isPresented: $show) {
                Popup(
                    isPresented: $show,
                    title: "Delete File?",
                    message: "This action can’t be undone.",
                    systemImage: "trash",
                    primaryButtonTitle: "Delete",
                    primaryButtonRole: .destructive,
                    accentColor: .red,
                    placement: .center,
                    primaryButtonAction: { print("Deleted") },
                    secondaryButtonTitle: "Cancel",
                    secondaryButtonRole: .cancel,
                    secondaryButtonAction: { print("Cancelled") }
                )
            }
        }
    }
    return Demo()
}
