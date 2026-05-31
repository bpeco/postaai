import SwiftUI

struct HoyScreen: View {
    @Environment(AppViewModel.self) private var vm

    var body: some View {
        VStack(spacing: 0) {
            switch vm.state {
            case .idle, .loading:
                Spacer()
                ProgressView().tint(Theme.Color.ink)
                Spacer()

            case .error:
                ErrorScreen(onRetry: {
                    Task { await vm.refresh() }
                })

            case .brokenContent:
                BrokenContentScreen()

            case .paused, .ok, .offlineCached:
                TopBar(
                    edition: vm.drop?.edition ?? "",
                    activeTab: vm.selectedTab,
                    isOffline: vm.isOffline,
                    onArchive:  { vm.selectedTab = .archive },
                    onSettings: { vm.selectedTab = .settings }
                )

                if vm.isPaused {
                    PausedScreen(message: vm.pauseMessage)
                } else if !vm.deck.isEmpty {
                    DropProgressBar(
                        number: vm.drop?.number ?? 0,
                        consumed: vm.cardsConsumed,
                        total: vm.totalCards
                    )
                    DeckView(
                        items: vm.deck,
                        alsoTodayRemaining: vm.alsoTodayCount,
                        onSwipe: { item, decision in vm.decide(item, decision) },
                        onDeepen: { card in vm.deepen(card) }
                    )
                } else if vm.drop != nil {
                    EndScreen(stats: vm.stats, onReshuffle: { vm.reshuffle() })
                }
            }
        }
    }
}
