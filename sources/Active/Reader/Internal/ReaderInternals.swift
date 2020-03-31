import Foundation

extension CSVReader: Failable {
    /// Reader status indicating whether there are remaning lines to read, the CSV has been completely parsed, or an error occurred and no further operation shall be performed.
    public enum Status {
        /// The CSV file hasn't been completely parsed.
        case active
        /// There are no more rows to read. The EOF has been reached.
        case finished
        /// An error has occurred and no further operations shall be performed with the reader instance.
        case failed(CSVError<CSVReader>)
    }
    
    /// The type of error raised by the CSV reader.
    public enum Error: Int {
        /// Some of the configuration values provided are invalid.
        case invalidConfiguration = 1
        /// The CSV data is invalid.
        case invalidInput = 2
//        /// The inferral process to figure out delimiters or header row status was unsuccessful.
//        case inferenceFailure = 3
        /// The input stream failed.
        case streamFailure = 4
    }
    
    public static var errorDomain: String {
        "Reader"
    }
    
    public static func errorDescription(for failure: Error) -> String {
        switch failure {
        case .invalidConfiguration: return "Invalid configuration"
        //        case .inferenceFailure: return "Inference failure"
        case .invalidInput: return "Invalid input"
        case .streamFailure: return "Stream failure"
        }
    }
}

extension CSVReader {
    /// Private configuration variables for the CSV reader.
    internal struct Settings {
        /// The unicode scalar delimiters for fields and rows.
        let delimiters: Delimiter.RawPair
        /// The unicode scalar used as encapsulator and escaping character (when printed two times).
        let escapingScalar: Unicode.Scalar?
        /// The characters set to be trimmed at the beginning and ending of each field.
        let trimCharacters: CharacterSet
        
        /// Creates the inmutable reader settings from the user provided configuration values.
        /// - parameter configuration: The configuration values provided by the API user.
        /// - parameter decoder: The instance providing the input `Unicode.Scalar`s.
        /// - parameter buffer: Small buffer use to store `Unicode.Scalar` values that have been read from the input, but haven't yet been processed.
        /// - throws: `CSVError<CSVReader>` exclusively.
        init(configuration: Configuration, decoder: ScalarDecoder, buffer: ScalarBuffer) throws {
            // 1. Figure out the field and row delimiters.
            switch (configuration.delimiters.field.rawValue, configuration.delimiters.row.rawValue) {
            case (nil, nil):
                self.delimiters = try CSVReader.inferDelimiters(decoder: decoder, buffer: buffer)
            case (nil, let row):
                self.delimiters = try CSVReader.inferFieldDelimiter(rowDelimiter: row, decoder: decoder, buffer: buffer)
            case (let field, nil):
                self.delimiters = try CSVReader.inferRowDelimiter(fieldDelimiter: field, decoder: decoder, buffer: buffer)
            case (let field, let row) where !field.elementsEqual(row):
                self.delimiters = (.init(field), .init(row))
            case (let delimiter, _):
                throw Error.invalidDelimiters(delimiter)
            }
            // 2. Set the escaping scalar.
            self.escapingScalar = configuration.escapingStrategy.scalar
            // 3. Set the trim characters set.
            self.trimCharacters = configuration.trimStrategry
            // 4. Ensure trim character set doesn't contain the field delimiter.
            guard delimiters.field.allSatisfy({ !self.trimCharacters.contains($0) }) else {
                throw Error.invalidTrimCharacters(self.trimCharacters, delimiter: configuration.delimiters.field.rawValue)
            }
            // 5. Ensure trim character set doesn't contain the row delimiter.
            guard delimiters.row.allSatisfy({ !self.trimCharacters.contains($0) }) else {
                throw Error.invalidTrimCharacters(self.trimCharacters, delimiter: configuration.delimiters.row.rawValue)
            }
            // 6. Ensure trim character set does not include escaping scalar
            if let escapingScalar = self.escapingScalar, self.trimCharacters.contains(escapingScalar) {
                throw Error.invalidTrimCharacters(self.trimCharacters, escapingScalar: escapingScalar)
            }
        }
    }
}

fileprivate extension CSVReader.Error {
    /// Error raised when the field and row delimiters are the same.
    /// - parameter delimiter: The indicated field and row delimiters.
    static func invalidDelimiters(_ delimiter: String.UnicodeScalarView) -> CSVError<CSVReader> {
        .init(.invalidConfiguration,
              reason: "The field and row delimiters cannot be the same.",
              help: "Set different delimiters for field and rows.",
              userInfo: ["Delimiter": delimiter])
    }
    /// Error raised when a delimiter (whether row or field) is included in the trim character set.
    static func invalidTrimCharacters(_ trimCharacters: CharacterSet, delimiter: String.UnicodeScalarView) -> CSVError<CSVReader> {
        .init(.invalidConfiguration,
              reason: "The trim character set includes delimiter characters.",
              help: "Remove the delimiter scalars from the trim character set.",
              userInfo: ["Delimiter": delimiter, "Trim characters": trimCharacters])
    }
    /// Error raised when the escaping scalar has been included in the trim character set.
    /// - parameter escapingScalar: The selected escaping scalar.
    /// - parameter trimCharacters: The character set selected for trimming.
    static func invalidTrimCharacters(_ trimCharacters: CharacterSet, escapingScalar: Unicode.Scalar) -> CSVError<CSVReader> {
        .init(.invalidConfiguration,
              reason: "The trim characters set includes the escaping scalar.",
              help: "Remove the escaping scalar from the trim characters set.",
              userInfo: ["Escaping scalar": escapingScalar, "Trim characters": trimCharacters])
    }
}
