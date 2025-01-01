import Cocoa
import CoreGraphics

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var eventMonitor: Any?
    
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request accessibility permissions
        let trusted = AXIsProcessTrusted()
        if !trusted {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "Please grant accessibility permission in System Settings > Privacy & Security > Accessibility"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Cancel")
            
            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
        }
        
        // Create the status item in the menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Set up the menu bar icon
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: "Zoom Control")
        }
        
        setupMenu()
        setupEventMonitor()
    }
    
    func setupMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Zoom Control Active", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }
    
    func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let self = self else { return }
            
            // Check if Control key is pressed
            if event.modifierFlags.contains(.control) {
                let delta = event.deltaY
                
                // Only trigger on significant scroll movements
                if abs(delta) > 0.1 {
                    // Scroll up (negative) = zoom in, scroll down (positive) = zoom out
                    let zoomIn = delta < 0
                    self.performZoom(zoomIn: zoomIn)
                    
                    // Add a small delay to prevent rapid-fire zooming
                    Thread.sleep(forTimeInterval: 0.05)
                }
            }
        }
    }
    
    func performZoom(zoomIn: Bool) {
        // Simulate Command + or Command -
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Create key down event for Command key
        let cmdKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)  // Command
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: zoomIn ? 0x1B : 0x18, keyDown: true)  // 0x18 for +, 0x1B for -
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: zoomIn ? 0x1B : 0x18, keyDown: false)
        let cmdKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        
        // Press Command
        cmdKeyDown?.post(tap: .cghidEventTap)
        
        // Press and release the + or - key
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
        
        // Release Command
        cmdKeyUp?.post(tap: .cghidEventTap)
    }
    
    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
