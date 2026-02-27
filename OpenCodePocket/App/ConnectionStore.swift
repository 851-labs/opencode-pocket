import Foundation
import Observation
import OpenCodeNetworking

#if os(macOS)
  import Darwin
#endif

@MainActor
@Observable
final class ConnectionStore {
  var baseURL: String
  var username: String
  var password: String
  var useBasicAuth: Bool
  var directory: String

  var isConnecting = false
  var isConnected = false
  var serverVersion: String?
  var connectionError: String?
  var eventConnectionState = "Disconnected"

  private(set) var client: OpenCodeClient?
  weak var lifecycleCoordinator: ConnectionLifecycleCoordinating?

  private let settingsStore: ConnectionSettingsStore

  #if os(macOS)
    private let localServerRuntime = ManagedLocalOpenCodeServer()
    private var connectedLocalServerOwnership: ManagedLocalOpenCodeServer.EndpointOwnership?
  #endif

  init(settingsStore: ConnectionSettingsStore = ConnectionSettingsStore()) {
    self.settingsStore = settingsStore

    let settings = settingsStore.loadSettings()
    baseURL = settings.baseURL
    username = settings.username
    useBasicAuth = settings.useBasicAuth
    directory = settings.directory

    password = settingsStore.loadPassword(baseURL: settings.baseURL, username: settings.username) ?? ""

  }

  var resolvedDirectory: String? {
    directory.trimmedNonEmpty
  }

  func connect() async {
    guard !isConnecting else { return }

    isConnecting = true
    connectionError = nil

    defer {
      isConnecting = false
    }

    do {
      #if os(macOS)
        try await connectUsingManagedLocalServer()
      #else
        try await connectUsingRemoteServer()
      #endif

      if isConnected {
        await lifecycleCoordinator?.connectionDidConnect()
      }
    } catch {
      isConnected = false
      eventConnectionState = "Disconnected"
      connectionError = error.localizedDescription

      #if os(macOS)
        connectedLocalServerOwnership = nil
      #endif
    }
  }

  func disconnect() {
    lifecycleCoordinator?.connectionDidDisconnect()
    client = nil
    isConnected = false
    eventConnectionState = "Disconnected"

    #if os(macOS)
      if connectedLocalServerOwnership == .managed {
        localServerRuntime.stopManagedProcess()
      }
      connectedLocalServerOwnership = nil
    #endif
  }

  func stopManagedLocalServerForTermination() {
    #if os(macOS)
      if connectedLocalServerOwnership == .managed {
        localServerRuntime.stopManagedProcess()
      }
      connectedLocalServerOwnership = nil
    #endif
  }

  private func normalizedBaseURL() throws -> URL {
    var value = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty else {
      throw OpenCodeClientError.message("Server URL is required")
    }

    if !value.contains("://") {
      value = "http://\(value)"
    }

    guard let url = URL(string: value), let scheme = url.scheme, !scheme.isEmpty else {
      throw OpenCodeClientError.invalidURL(value)
    }

    return url
  }

  private func normalizedBaseURLForPersistence(fallback: URL? = nil) -> String {
    if let normalized = try? normalizedBaseURL() {
      return normalized.absoluteString
    }

    let trimmed = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
    if !trimmed.isEmpty {
      return trimmed
    }

    return fallback?.absoluteString ?? ""
  }

  private func connectUsingRemoteServer() async throws {
    let normalizedURL = try normalizedBaseURL()

    let resolvedUsername = username.trimmedNonEmpty
    let resolvedPassword: String?

    if useBasicAuth {
      if let directPassword = password.trimmedNonEmpty {
        resolvedPassword = directPassword
      } else if let resolvedUsername {
        resolvedPassword = settingsStore.loadPassword(baseURL: normalizedURL.absoluteString, username: resolvedUsername)
        password = resolvedPassword ?? ""
      } else {
        resolvedPassword = nil
      }
    } else {
      resolvedPassword = nil
    }

    let nextClient = OpenCodeClient(
      configuration: OpenCodeClientConfiguration(
        baseURL: normalizedURL,
        username: useBasicAuth ? resolvedUsername : nil,
        password: useBasicAuth ? resolvedPassword : nil,
        directory: resolvedDirectory
      )
    )

    let health = try await nextClient.health()

    client = nextClient
    isConnected = health.healthy
    serverVersion = health.version
    eventConnectionState = "Connected"

    #if os(macOS)
      connectedLocalServerOwnership = nil
    #endif

    saveConnectionSettings(
      using: normalizedURL.absoluteString
    )

  }

  #if os(macOS)
    private func connectUsingManagedLocalServer() async throws {
      eventConnectionState = "Starting local server"

      let endpoint = try await localServerRuntime.establishEndpoint()
      let nextClient = OpenCodeClient(
        configuration: OpenCodeClientConfiguration(
          baseURL: endpoint.baseURL,
          username: endpoint.username,
          password: endpoint.password,
          directory: resolvedDirectory
        )
      )

      let health = try await nextClient.health()

      client = nextClient
      isConnected = health.healthy
      serverVersion = health.version
      eventConnectionState = "Connected (Local)"
      connectedLocalServerOwnership = endpoint.ownership

      let persistedBaseURL = normalizedBaseURLForPersistence(fallback: endpoint.baseURL)
      if !persistedBaseURL.isEmpty {
        saveConnectionSettings(
          using: persistedBaseURL
        )
      }

    }
  #endif

  private func saveConnectionSettings(
    using normalizedBaseURL: String
  ) {
    let hadSavedSettings = settingsStore.hasSavedSettings()
    let previousSettings = settingsStore.loadSettings()
    let previousBaseURL = previousSettings.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
    let previousUsername = previousSettings.username.trimmedNonEmpty

    let currentBaseURL = normalizedBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
    let currentUsername = username.trimmedNonEmpty
    let currentPassword = password.trimmedNonEmpty

    let settings = ConnectionSettings(
      baseURL: normalizedBaseURL,
      username: username,
      useBasicAuth: useBasicAuth,
      directory: directory
    )
    settingsStore.saveSettings(settings)

    if useBasicAuth, let currentUsername, let currentPassword {
      settingsStore.savePassword(currentPassword, baseURL: normalizedBaseURL, username: currentUsername)
    } else if let currentUsername {
      settingsStore.deletePassword(baseURL: normalizedBaseURL, username: currentUsername)
    }

    if hadSavedSettings, let previousUsername, !previousBaseURL.isEmpty {
      let credentialsChanged = currentUsername == nil || currentUsername != previousUsername || currentBaseURL != previousBaseURL

      if credentialsChanged {
        settingsStore.deletePassword(baseURL: previousBaseURL, username: previousUsername)
      }
    }
  }
}

#if os(macOS)
  @MainActor
  private final class ManagedLocalOpenCodeServer {
    enum EndpointOwnership {
      case attached
      case managed
    }

    struct Endpoint {
      let baseURL: URL
      let username: String?
      let password: String?
      let ownership: EndpointOwnership
    }

    private let fileManager: FileManager

    private var managedProcess: Process?
    private var managedEndpoint: Endpoint?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?
    private var outputBuffer = Data()

    init(fileManager: FileManager = .default) {
      self.fileManager = fileManager
    }

    func establishEndpoint() async throws -> Endpoint {
      if
        let managedEndpoint,
        managedEndpoint.ownership == .managed,
        await isHealthy(managedEndpoint)
      {
        return managedEndpoint
      }

      if let attached = await existingLocalEndpoint() {
        managedEndpoint = attached
        return attached
      }

      let executablePath = try resolveExecutablePath()
      var lastError: Error?

      for _ in 0 ..< 4 {
        do {
          let endpoint = try await launchManagedServer(executablePath: executablePath)
          managedEndpoint = endpoint
          return endpoint
        } catch {
          lastError = error
          stopManagedProcess()
        }
      }

      throw lastError ?? OpenCodeClientError.message("Failed to start local OpenCode server.")
    }

    func stopManagedProcess() {
      stdoutPipe?.fileHandleForReading.readabilityHandler = nil
      stderrPipe?.fileHandleForReading.readabilityHandler = nil
      stdoutPipe = nil
      stderrPipe = nil

      guard let managedProcess else {
        managedEndpoint = nil
        return
      }

      if managedProcess.isRunning {
        let pid = managedProcess.processIdentifier
        managedProcess.terminate()

        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
          if managedProcess.isRunning {
            kill(pid_t(pid), SIGKILL)
          }
        }
      }

      self.managedProcess = nil
      managedEndpoint = nil
    }

    private func existingLocalEndpoint() async -> Endpoint? {
      let candidates = [
        "http://127.0.0.1:4096",
        "http://localhost:4096",
      ]

      for value in candidates {
        guard let url = URL(string: value) else { continue }

        let endpoint = Endpoint(
          baseURL: url,
          username: nil,
          password: nil,
          ownership: .attached
        )

        if await isHealthy(endpoint) {
          return endpoint
        }
      }

      return nil
    }

    private func launchManagedServer(executablePath: String) async throws -> Endpoint {
      let port = try availableLoopbackPort()
      let username = "opencode"
      let password = UUID().uuidString

      let process = Process()
      process.executableURL = URL(fileURLWithPath: executablePath)
      process.arguments = [
        "serve",
        "--hostname",
        "127.0.0.1",
        "--port",
        "\(port)",
        "--log-level",
        "WARN",
      ]

      var environment = ProcessInfo.processInfo.environment
      environment["OPENCODE_SERVER_USERNAME"] = username
      environment["OPENCODE_SERVER_PASSWORD"] = password
      environment["PATH"] = resolvedPath(environment["PATH"])
      process.environment = environment

      outputBuffer = Data()
      let stdout = Pipe()
      let stderr = Pipe()
      stdoutPipe = stdout
      stderrPipe = stderr
      process.standardOutput = stdout
      process.standardError = stderr
      installOutputCapture(stdout: stdout, stderr: stderr)

      try process.run()
      managedProcess = process

      let endpointURL = URL(string: "http://127.0.0.1:\(port)")!
      let endpoint = Endpoint(
        baseURL: endpointURL,
        username: username,
        password: password,
        ownership: .managed
      )

      let deadline = Date().addingTimeInterval(10)
      while Date() < deadline {
        if await isHealthy(endpoint) {
          return endpoint
        }

        if !process.isRunning {
          throw OpenCodeClientError.message(
            "Local OpenCode server exited before becoming healthy.\n\(latestOutput())"
          )
        }

        try await Task.sleep(nanoseconds: 200_000_000)
      }

      throw OpenCodeClientError.message(
        "Timed out waiting for local OpenCode server startup.\n\(latestOutput())"
      )
    }

    private func installOutputCapture(stdout: Pipe, stderr: Pipe) {
      stdout.fileHandleForReading.readabilityHandler = { [weak self] handle in
        let data = handle.availableData
        guard !data.isEmpty else { return }

        Task { @MainActor in
          self?.appendOutput(data)
        }
      }

      stderr.fileHandleForReading.readabilityHandler = { [weak self] handle in
        let data = handle.availableData
        guard !data.isEmpty else { return }

        Task { @MainActor in
          self?.appendOutput(data)
        }
      }
    }

    private func appendOutput(_ data: Data) {
      outputBuffer.append(data)

      let limit = 32768
      if outputBuffer.count > limit {
        outputBuffer.removeFirst(outputBuffer.count - limit)
      }
    }

    private func latestOutput() -> String {
      guard !outputBuffer.isEmpty else {
        return "No output captured from local server process."
      }

      let text = String(decoding: outputBuffer, as: UTF8.self)
      let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmed.isEmpty ? "No output captured from local server process." : trimmed
    }

    private func isHealthy(_ endpoint: Endpoint) async -> Bool {
      let client = OpenCodeClient(
        configuration: OpenCodeClientConfiguration(
          baseURL: endpoint.baseURL,
          username: endpoint.username,
          password: endpoint.password,
          directory: nil
        )
      )

      guard let health = try? await client.health() else {
        return false
      }

      return health.healthy
    }

    private func resolveExecutablePath() throws -> String {
      let environment = ProcessInfo.processInfo.environment

      var candidates: [String] = []

      if let explicitPath = environment["OPENCODE_BIN_PATH"]?.trimmedNonEmpty {
        candidates.append(explicitPath)
      }

      let homeDirectory = NSHomeDirectory()
      if !homeDirectory.isEmpty {
        candidates.append("\(homeDirectory)/.opencode/bin/opencode")
      }

      candidates.append(contentsOf: [
        "/opt/homebrew/bin/opencode",
        "/usr/local/bin/opencode",
        "/usr/bin/opencode",
      ])

      if let path = environment["PATH"] {
        let pathCandidates = path.split(separator: ":").map { String($0) }
        candidates.append(contentsOf: pathCandidates.map { "\($0)/opencode" })
      }

      var seen = Set<String>()
      for candidate in candidates {
        let expanded = NSString(string: candidate).expandingTildeInPath
        guard !seen.contains(expanded) else { continue }

        seen.insert(expanded)
        if fileManager.isExecutableFile(atPath: expanded) {
          return expanded
        }
      }

      throw OpenCodeClientError.message(
        "Could not find the `opencode` CLI. Install it and ensure it is available in ~/.opencode/bin/opencode, /opt/homebrew/bin/opencode, /usr/local/bin/opencode, or set OPENCODE_BIN_PATH."
      )
    }

    private func resolvedPath(_ currentPath: String?) -> String {
      var parts = currentPath?.split(separator: ":").map(String.init) ?? []

      let preferred = [
        "\(NSHomeDirectory())/.opencode/bin",
        "/opt/homebrew/bin",
        "/usr/local/bin",
        "/usr/bin",
        "/bin",
      ]

      for path in preferred where !path.isEmpty && !parts.contains(path) {
        parts.append(path)
      }

      return parts.joined(separator: ":")
    }

    private func availableLoopbackPort() throws -> Int {
      let socketDescriptor = socket(AF_INET, SOCK_STREAM, 0)
      guard socketDescriptor >= 0 else {
        throw OpenCodeClientError.message("Failed to reserve a local port.")
      }
      defer {
        _ = close(socketDescriptor)
      }

      var address = sockaddr_in()
      address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
      address.sin_family = sa_family_t(AF_INET)
      address.sin_port = in_port_t(0).bigEndian
      address.sin_addr = in_addr(s_addr: inet_addr("127.0.0.1"))

      let bindResult = withUnsafePointer(to: &address) { pointer in
        pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
          bind(socketDescriptor, sockaddrPointer, socklen_t(MemoryLayout<sockaddr_in>.size))
        }
      }

      guard bindResult == 0 else {
        throw OpenCodeClientError.message("Failed to reserve a local port.")
      }

      var resolvedAddress = sockaddr_in()
      var length = socklen_t(MemoryLayout<sockaddr_in>.size)

      let nameResult = withUnsafeMutablePointer(to: &resolvedAddress) { pointer in
        pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
          getsockname(socketDescriptor, sockaddrPointer, &length)
        }
      }

      guard nameResult == 0 else {
        throw OpenCodeClientError.message("Failed to resolve a local port.")
      }

      let port = Int(UInt16(bigEndian: resolvedAddress.sin_port))
      guard port > 0 else {
        throw OpenCodeClientError.message("Failed to resolve a local port.")
      }

      return port
    }
  }
#endif
