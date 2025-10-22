import SwiftUI

struct QuickActionsView: View {
    @ObservedObject var viewModel: QuickActionViewModel

    var body: some View {
        List(viewModel.actions) { action in
            Button {
                viewModel.trigger(action)
            } label: {
                QuickActionRow(action: action)
            }
            .buttonStyle(.plain)
        }
        .listStyle(.carousel)
        .navigationTitle("Quick Actions")
        .alert(
            viewModel.feedback?.title ?? "",
            isPresented: Binding<Bool>(
                get: { viewModel.feedback != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.dismissFeedback()
                    }
                }
            ),
            actions: {
                Button("OK", role: .cancel) {
                    viewModel.dismissFeedback()
                }
            },
            message: {
                if let message = viewModel.feedback?.message {
                    Text(message)
                }
            }
        )
        .confirmationDialog(
            viewModel.confirmationTitle,
            isPresented: Binding<Bool>(
                get: { viewModel.isConfirmationDialogPresented },
                set: { value in
                    if !value {
                        viewModel.cancelPendingAction()
                    }
                }
            ),
            presenting: viewModel.pendingAction
        ) { action in
            Button("Confirm") {
                viewModel.confirmPendingAction()
            }
            Button("Cancel", role: .cancel) {
                viewModel.cancelPendingAction()
            }
        } message: { action in
            Text(action.confirmationPrompt)
        }
    }
}

struct QuickActionRow: View {
    let action: QuickAction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: action.systemImageName)
                .font(.title3)
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(action.title)
                    .font(.headline)
                Text(action.subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
struct QuickActionsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            QuickActionsView(viewModel: QuickActionViewModel())
        }
    }
}
#endif
