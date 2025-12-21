import Foundation
import os

import protocol Logging.LogHandler
import struct Logging.Logger

public struct AppLogger {
  private let label: String
  private let handler: any LogHandler
  public var logLevel: Logger.Level = .info

  init(label: String, handler: (any LogHandler)? = nil) {
    self.label = label
    self.handler = handler ?? SwiftOsLog(label: label)
  }

  public func log(
    level: Logger.Level,
    message: Logger.Message,
    metadata: Logger.Metadata? = nil,
    source: String? = nil,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) {
    if self.logLevel <= level {
      self.handler.log(
        level: level,
        message: message,
        metadata: metadata,
        source: source ?? "",
        file: file,
        function: function,

        line: line
      )
    }
  }

  public func trace(
    _ message: Logger.Message,
    metadata: Logger.Metadata? = nil,
    source: String? = nil,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) {
    self.log(
      level: .trace,
      message: message,
      metadata: metadata,
      source: source,
      file: file,
      function: function,
      line: line
    )
  }

  public func debug(
    _ message: Logger.Message,
    metadata: Logger.Metadata? = nil,
    source: String? = nil,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) {
    self.log(
      level: .debug,
      message: message,
      metadata: metadata,
      source: source,
      file: file,
      function: function,
      line: line
    )
  }

  public func info(
    _ message: Logger.Message,
    metadata: Logger.Metadata? = nil,
    source: String? = nil,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) {
    self.log(
      level: .info,
      message: message,
      metadata: metadata,
      source: source,
      file: file,
      function: function,
      line: line
    )
  }

  public func notice(
    _ message: Logger.Message,
    metadata: Logger.Metadata? = nil,
    source: String? = nil,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) {
    self.log(
      level: .notice,
      message: message,
      metadata: metadata,
      source: source,
      file: file,
      function: function,
      line: line
    )
  }

  public func warning(
    _ message: Logger.Message,
    metadata: Logger.Metadata? = nil,
    source: String? = nil,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) {
    self.log(
      level: .warning,
      message: message,
      metadata: metadata,
      source: source,
      file: file,
      function: function,
      line: line
    )
  }

  public func error(
    _ message: Logger.Message,
    metadata: Logger.Metadata? = nil,
    source: String? = nil,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) {
    self.log(
      level: .error,
      message: message,
      metadata: metadata,
      source: source,
      file: file,
      function: function,
      line: line
    )
  }

  public func critical(
    _ message: Logger.Message,
    metadata: Logger.Metadata? = nil,
    source: String? = nil,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
  ) {
    self.log(
      level: .critical,
      message: message,
      metadata: metadata,
      source: source,
      file: file,
      function: function,
      line: line
    )
  }
}

private struct SwiftOsLog: LogHandler {
  private let label: String
  private let logger: os.Logger
  var metadata: Logger.Metadata = [:]
  var logLevel: Logger.Level = .info

  init(label: String) {
    self.label = label
    logger = os.Logger(subsystem: "com.sewingplanner.settings", category: "")
  }

  func log(
    level: Logger.Level,
    message: Logger.Message,
    metadata: Logger.Metadata?,
    source: String,
    file: String,
    function: String,
    line: UInt
  ) {
    let timestamp = ISO8601DateFormatter().string(from: Date())

    let levelString = level.rawValue.uppercased()

    let mergedMetadata = Self.mergeMetadata(
      base: self.metadata,
      explicit: metadata
    )

    let location = "\(file) \(function) #line:\(line) \(source)"

    // Format metadata
    let metadataString =
      mergedMetadata?.map { "\($0.key)=\($0.value)" }.joined(separator: ", ") ?? ""

    logger.log(
      level: OSLogType.fromSwiftLog(level: level),
      "\(label, privacy: .public) \(timestamp, privacy: .public) \(levelString, privacy: .public) \(message, privacy: .public) \(location, privacy: .public) [\(metadataString, privacy: .public)]"
    )
  }

  subscript(metadataKey key: String) -> Logger.Metadata.Value? {
    get {
      return metadata[key]
    }
    set {
      metadata[key] = newValue
    }
  }

  static func mergeMetadata(
    base: Logger.Metadata,
    explicit: Logger.Metadata?
  ) -> Logger.Metadata? {
    var metadata = base

    guard let explicit else {
      // all per-log-statement values are empty
      return metadata
    }

    metadata.merge(explicit, uniquingKeysWith: { _, explicit in explicit })

    return metadata
  }
}

extension Logger.MetadataValue {
  /// The different styles of privacy masks that can be applied to a metadata value.
  internal enum PrivacyMask {
    /// The value will be hashed and converted into an 8 character hex representation.
    case hash
    /// Replaces the value with `*****`.
    case redact
  }

  /// Replaces the value with `*****`.
  ///
  /// This is great for when the actual value is not of importance and should be masked when not debugging.
  ///
  /// For example:
  ///
  ///     let logger: Logger = ...
  ///     logger.info(
  ///       "replaced value with mask pattern",
  ///       metadata: [
  ///         "password": .mask(user.password)
  ///       ]
  ///     )
  public static func mask(_ value: String) -> Logger.MetadataValue {
    return .stringConvertible(MaskedValue(value, mask: .redact))
  }

  /// The value will be hashed and converted into an 8 character hex representation.
  ///
  /// This is great for when identity of value between individual logs is important, but the actual value should still be masked.
  ///
  /// For example:
  ///
  ///     let logger: Logger = ...
  ///     logger.info(
  ///       "obfuscated value",
  ///       metadata: [
  ///         "ip_address": .hash(user.ipAddress)
  ///       ]
  ///     )
  public static func hash(_ value: String) -> Logger.MetadataValue {
    return .stringConvertible(MaskedValue(value, mask: .hash))
  }
}

struct MaskedValue: CustomStringConvertible {
  let underlying: String

  private let mask: Logger.MetadataValue.PrivacyMask

  var description: String {
    switch mask {
      case .hash: return hash("\(underlying)")
      case .redact: return "*****"
    }
  }

  fileprivate init(_ value: String, mask: Logger.MetadataValue.PrivacyMask) {
    underlying = value
    self.mask = mask
  }

  private func hash(_ value: String) -> String {
    var hasher = Hasher()
    hasher.combine(value)
    return "\(String(format: "%x", hasher.finalize()))"
  }
}

// the type of Os Logger's logs
extension OSLogType {
  static func fromSwiftLog(level: Logger.Level) -> Self {
    switch level {
      case .trace:
        /// `OSLog` doesn't have `trace`, so use `debug`
        return .debug
      case .debug:
        return .debug
      case .info:
        return .info
      case .notice:
        // https://developer.apple.com/documentation/os/logging/generating_log_messages_from_your_code
        // According to the documentation, `default` is `notice`.
        return .default
      case .warning:
        /// `OSLog` doesn't have `warning`, so use `info`
        return .info
      case .error:
        return .error
      case .critical:
        return .fault
    }
  }
}
