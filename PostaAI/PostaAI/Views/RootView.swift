import SwiftUI

struct RootView: View {
    @State private var vm = AppViewModel()
    @State private var showFirstDropTransition = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Theme.Color.paper.ignoresSafeArea()

            if !vm.hasCompletedOnboarding {
                // Arc A: el callback setea showFirstDropTransition y completa
                // el onboarding en la misma frame, así SwiftUI batchea ambos
                // updates y nunca se renderea el deck/tutorial en el gap.
                OnboardingScreen(onComplete: {
                    showFirstDropTransition = true
                    vm.completeOnboarding()
                    Task {
                        try? await Task.sleep(nanoseconds: 2_500_000_000)
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showFirstDropTransition = false
                        }
                    }
                })
                .transition(.opacity)
            } else if showFirstDropTransition {
                FirstDropTransition()
                    .transition(.opacity)
            } else {
                VStack(spacing: 0) {
                    switch vm.selectedTab {
                    case .hoy:
                        HoyScreen()
                    case .archive:
                        ScreenChrome(title: nil) { ArchiveScreen() }
                    case .settings:
                        ScreenChrome(title: nil) { SettingsScreen() }
                    }
                    BottomNav(tab: vm.selectedTab, onChange: { vm.selectedTab = $0 })
                }

                if vm.showCoach && vm.selectedTab == .hoy && vm.cardsConsumed == 0 && vm.totalCards > 0 {
                    CoachTutorial(onComplete: { withAnimation { vm.dismissCoach() } })
                        .zIndex(80)
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.22), value: vm.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.4), value: showFirstDropTransition)
        .environment(vm)
        .sheet(item: Binding(get: { vm.detailCard }, set: { vm.detailCard = $0 })) { card in
            DetailView(
                card: card,
                isSaved: vm.savedIds.contains(card.id),
                onClose: { vm.closeDetail() },
                onSave: { vm.saveFromDetail(card.id) }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .task {
            await vm.load()
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Re-fetch al volver a foreground si el cache pasa el threshold de 15min.
            // Guard contra el primer .active del cold start (state == .idle todavía).
            if newPhase == .active, vm.state != .idle, vm.cacheIsStale {
                Task { await vm.refresh() }
            }
        }
    }
}

private struct ScreenChrome<Content: View>: View {
    let title: String?
    @ViewBuilder let content: () -> Content
    var body: some View { content() }
}

// Arc A — cierre visual entre onboarding y deck. Sirve incluso si el fetch ya
// terminó (consistencia visual).
private struct FirstDropTransition: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("ARMANDO")
                .font(.mono(11, weight: .medium))
                .kerning(2.0)
                .foregroundStyle(Theme.Color.inkMute)
            Text("Tu primer\ndrop.")
                .font(.bricolage(44, weight: .extraBold))
                .tracking(-1.32)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.Color.ink)
            ProgressView()
                .tint(Theme.Color.ink)
                .padding(.top, 12)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
