import Foundation

public struct AgentDescriptor: Codable, Hashable, Identifiable, Sendable {
  public let name: String
  public let description: String?
  public let mode: String
  public let hidden: Bool?

  public var id: String {
    name
  }

  public init(name: String, description: String?, mode: String, hidden: Bool?) {
    self.name = name
    self.description = description
    self.mode = mode
    self.hidden = hidden
  }
}

public struct ProviderCatalogResponse: Decodable, Sendable {
  public let providers: [ProviderDescriptor]
  public let defaultModels: [String: String]

  enum CodingKeys: String, CodingKey {
    case providers
    case defaultModels = "default"
  }

  public init(providers: [ProviderDescriptor], defaultModels: [String: String]) {
    self.providers = providers
    self.defaultModels = defaultModels
  }
}

public struct ProviderDescriptor: Decodable, Hashable, Sendable {
  public let id: String
  public let name: String
  public let models: [String: ProviderModelDescriptor]

  public init(id: String, name: String, models: [String: ProviderModelDescriptor]) {
    self.id = id
    self.name = name
    self.models = models
  }
}

public struct ProviderModelLimitDescriptor: Decodable, Hashable, Sendable {
  public let context: Int?
  public let input: Int?
  public let output: Int?

  public init(context: Int?, input: Int?, output: Int?) {
    self.context = context
    self.input = input
    self.output = output
  }
}

public struct ProviderModelDescriptor: Decodable, Hashable, Sendable {
  public let id: String
  public let providerID: String
  public let name: String
  public let variants: [String: JSONValue]?
  public let limit: ProviderModelLimitDescriptor?

  public init(
    id: String,
    providerID: String,
    name: String,
    variants: [String: JSONValue]?,
    limit: ProviderModelLimitDescriptor? = nil
  ) {
    self.id = id
    self.providerID = providerID
    self.name = name
    self.variants = variants
    self.limit = limit
  }
}

public struct ModelOption: Hashable, Identifiable, Sendable {
  public let providerID: String
  public let providerName: String
  public let modelID: String
  public let modelName: String
  public let variants: [String]
  public let contextWindow: Int?

  public var id: String {
    "\(providerID)::\(modelID)"
  }

  public var selector: ModelSelector {
    ModelSelector(providerID: providerID, modelID: modelID)
  }

  public var displayLabel: String {
    if variants.isEmpty {
      return modelName
    }
    return "\(modelName) (\(variants.count) variants)"
  }

  public init(
    providerID: String,
    providerName: String,
    modelID: String,
    modelName: String,
    variants: [String],
    contextWindow: Int? = nil
  ) {
    self.providerID = providerID
    self.providerName = providerName
    self.modelID = modelID
    self.modelName = modelName
    self.variants = variants
    self.contextWindow = contextWindow
  }
}

public struct ModelProviderGroup: Hashable, Identifiable, Sendable {
  public let providerID: String
  public let providerName: String
  public let models: [ModelOption]

  public var id: String {
    providerID
  }

  public init(providerID: String, providerName: String, models: [ModelOption]) {
    self.providerID = providerID
    self.providerName = providerName
    self.models = models
  }
}
