import Foundation

enum Command: String {
    case start
    case pause
    case cancel
}

let args = CommandLine.arguments.dropFirst()
guard let sub = args.first, let cmd = Command(rawValue: sub.lowercased()) else {
    fputs("Usage: clippyctl <start|pause|cancel>\n", stderr)
    exit(2)
}

let center = DistributedNotificationCenter.default()
switch cmd {
case .start:
    center.post(name: Notification.Name("ClippyTyper.StartTyping"), object: nil)
case .pause:
    center.post(name: Notification.Name("ClippyTyper.PauseToggle"), object: nil)
case .cancel:
    center.post(name: Notification.Name("ClippyTyper.CancelTyping"), object: nil)
}

