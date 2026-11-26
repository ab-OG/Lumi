import Foundation
import Testing
@preconcurrency import MLXLMCommon
@testable import PluginLLMProviderMLX

@Suite("MLXTokenizerLoader 本地分词器加载回归测试")
struct MLXTokenizerLoaderTests {

    @Test("从本地模型目录通过 modelFolder 加载分词器")
    func loadTokenizerFromLocalModelFolder() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MLXTokenizerLoaderTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let tokenizerConfigJSON = """
        {
          "tokenizer_class": "GPT2Tokenizer",
          "bos_token": "<|endoftext|>",
          "eos_token": "<|endoftext|>",
          "unk_token": "<|endoftext|>"
        }
        """

        let tokenizerJSON = """
        {
          "version": "1.0",
          "model": {
            "type": "BPE",
            "vocab": {
              "<|endoftext|>": 0,
              "hello": 1,
              "world": 2
            },
            "merges": []
          }
        }
        """

        try tokenizerConfigJSON.write(
            to: tempDir.appendingPathComponent("tokenizer_config.json"),
            atomically: true,
            encoding: .utf8
        )
        try tokenizerJSON.write(
            to: tempDir.appendingPathComponent("tokenizer.json"),
            atomically: true,
            encoding: .utf8
        )

        let loader = MLXTokenizerLoader()
        let tokenizer = try await loader.load(from: tempDir)

        #expect(tokenizer.bosToken == "<|endoftext|>")
        #expect(tokenizer.eosToken == "<|endoftext|>")
        #expect(tokenizer.convertTokenToId("hello") == 1)
        #expect(tokenizer.convertIdToToken(1) == "hello")
        #expect(tokenizer.convertTokenToId("world") == 2)
        #expect(tokenizer.convertIdToToken(2) == "world")
    }
}
